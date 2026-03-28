variable "tf_api_token" {
  description = "Terraform Cloud API token"
  type        = string
  sensitive   = true
}

variable "tf_cloud_organization" {
  description = "Terraform Cloud organization name"
  type        = string
  sensitive   = true
}

variable "gh_pat" {
  description = "GitHub PAT for repository management"
  type        = string
  sensitive   = true
}

locals {
  cd_secrets = {
    TF_API_TOKEN          = var.tf_api_token
    TF_CLOUD_ORGANIZATION = var.tf_cloud_organization
    GH_PAT                = var.gh_pat
  }
  repos_with_terraform = { for k, v in var.repositories : k => v if length(v.terraform_stacks) > 0 }
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
