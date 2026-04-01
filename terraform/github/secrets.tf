locals {
  repos_with_terraform = { for k, v in var.repositories : k => v if v.has_terraform }

  cd_secrets = {
    INFISICAL_CLIENT_ID     = var.infisical_client_id
    INFISICAL_CLIENT_SECRET = var.infisical_client_secret
  }

  repo_secrets = { for pair in flatten([
    for repo_key, repo in local.repos_with_terraform : [
      for secret_key, secret_value in local.cd_secrets : {
        key   = "${repo_key}:${secret_key}"
        repo  = repo_key
        name  = secret_key
        value = secret_value
      }
    ]
  ]) : pair.key => pair }
}

resource "github_actions_secret" "this" {
  for_each = local.repo_secrets

  repository      = github_repository.this[each.value.repo].name
  secret_name     = each.value.name
  plaintext_value = each.value.value
}

resource "github_actions_variable" "infisical_project_id" {
  for_each = local.repos_with_terraform

  repository    = github_repository.this[each.key].name
  variable_name = "INFISICAL_PROJECT_ID"
  value         = var.infisical_project_id
}
