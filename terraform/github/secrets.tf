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
}

resource "github_actions_secret" "this" {
  for_each = local.cd_secrets

  repository      = github_repository.this["dotfiles"].name
  secret_name     = each.key
  plaintext_value = each.value
}
