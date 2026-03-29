data "bitwarden_item_login" "terraform_cloud" {
  search = "terraform-cloud"
}

locals {
  cd_secrets = {
    TF_API_TOKEN          = data.bitwarden_item_login.terraform_cloud.password
    TF_CLOUD_ORGANIZATION = one([for f in data.bitwarden_item_login.terraform_cloud.field : f.text if f.name == "organization"])
    GH_PAT                = data.bitwarden_item_login.github_pat.password
  }
  repos_with_terraform = { for k, v in var.repositories : k => v if v.has_terraform }
  # Cross product: repo × secret
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
