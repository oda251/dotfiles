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

# dotfilesリポジトリのCI/CDに必要なシークレット
resource "github_actions_secret" "tf_api_token" {
  repository      = github_repository.this["dotfiles"].name
  secret_name     = "TF_API_TOKEN"
  plaintext_value = var.tf_api_token
}

resource "github_actions_secret" "tf_cloud_organization" {
  repository      = github_repository.this["dotfiles"].name
  secret_name     = "TF_CLOUD_ORGANIZATION"
  plaintext_value = var.tf_cloud_organization
}

resource "github_actions_secret" "gh_pat" {
  repository      = github_repository.this["dotfiles"].name
  secret_name     = "GH_PAT"
  plaintext_value = var.gh_pat
}
