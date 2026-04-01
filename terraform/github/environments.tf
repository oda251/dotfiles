data "github_user" "current" {
  username = var.github_owner
}

resource "github_repository_environment" "production" {
  for_each = { for k, v in var.repositories : k => v if v.has_infisical }

  repository  = github_repository.this[each.key].name
  environment = "production"

  reviewers {
    users = [data.github_user.current.id]
  }

  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}

resource "github_actions_environment_secret" "infisical_client_id" {
  for_each = github_repository_environment.production

  repository      = each.value.repository
  environment     = each.value.environment
  secret_name     = "INFISICAL_CLIENT_ID"
  plaintext_value = data.infisical_secrets.terraform.secrets["INFISICAL_UNIVERSAL_AUTH_CLIENT_ID"].value
}

resource "github_actions_environment_secret" "infisical_client_secret" {
  for_each = github_repository_environment.production

  repository      = each.value.repository
  environment     = each.value.environment
  secret_name     = "INFISICAL_CLIENT_SECRET"
  plaintext_value = data.infisical_secrets.terraform.secrets["INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET"].value
}

resource "github_actions_environment_variable" "infisical_project_id" {
  for_each = github_repository_environment.production

  repository    = each.value.repository
  environment   = each.value.environment
  variable_name = "INFISICAL_PROJECT_ID"
  value         = var.infisical_project_id
}
