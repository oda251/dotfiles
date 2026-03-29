# Infisical secret declarations
# TF ensures secrets exist; user fills in values via Infisical UI.

locals {
  env_slug = "prod"

  # User-managed secrets: TF creates the entry, user sets the value.
  user_secrets = {
    GITHUB_PAT      = { folder = "/terraform", comment = "GitHub Personal Access Token" }
    TF_API_TOKEN    = { folder = "/terraform", comment = "Terraform Cloud API token" }
    TF_CLOUD_ORG    = { folder = "/terraform", comment = "Terraform Cloud organization name" }
    GRAFANA_API_KEY = { folder = "/terraform", comment = "Grafana Cloud org-level API key" }
  }
}

resource "infisical_secret_folder" "terraform" {
  name         = "terraform"
  env_slug     = local.env_slug
  workspace_id = var.infisical_project_id
  folder_path  = "/"
}

resource "infisical_secret_folder" "generated" {
  name         = "generated"
  env_slug     = local.env_slug
  workspace_id = var.infisical_project_id
  folder_path  = "/"
}

resource "infisical_secret" "user_managed" {
  for_each = local.user_secrets

  name         = each.key
  value        = ""
  comment      = each.value.comment
  env_slug     = local.env_slug
  workspace_id = var.infisical_project_id
  folder_path  = each.value.folder

  depends_on = [infisical_secret_folder.terraform]

  lifecycle {
    ignore_changes = [value]
  }
}

# --- Machine Identities ---

variable "infisical_org_id" {
  description = "Infisical organization ID"
  type        = string
}

resource "infisical_identity" "github_actions" {
  name   = "github-actions"
  role   = "member"
  org_id = var.infisical_org_id
}

resource "infisical_identity_universal_auth" "github_actions" {
  identity_id = infisical_identity.github_actions.id
}

output "github_actions_identity_id" {
  description = "Machine identity ID for GitHub Actions"
  value       = infisical_identity.github_actions.id
}

output "github_actions_client_id" {
  description = "Universal Auth client ID for GitHub Actions"
  value       = infisical_identity_universal_auth.github_actions.client_id
}

output "github_actions_client_secret" {
  description = "Universal Auth client secret for GitHub Actions (set as GH secret)"
  value       = infisical_identity_universal_auth.github_actions.client_secret
  sensitive   = true
}
