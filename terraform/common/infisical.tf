# Infisical secret declarations
# TF ensures secrets exist; user fills in values via Infisical UI.

locals {
  secret_folders = toset(["terraform", "generated"])

  # User-managed secrets: TF creates the entry, user sets the value.
  user_secrets = {
    GITHUB_PAT           = { folder = "/terraform", comment = "GitHub Personal Access Token" }
    TF_API_TOKEN         = { folder = "/terraform", comment = "Terraform Cloud API token" }
    TF_CLOUD_ORG         = { folder = "/terraform", comment = "Terraform Cloud organization name" }
    NEW_RELIC_API_KEY    = { folder = "/terraform", comment = "New Relic User API key" }
    NEW_RELIC_ACCOUNT_ID = { folder = "/terraform", comment = "New Relic account ID" }
  }
}


resource "infisical_secret_folder" "this" {
  for_each = local.secret_folders

  name             = each.value
  environment_slug = var.environment_slug
  project_id       = var.infisical_project_id
  folder_path      = "/"
}

resource "infisical_secret" "user_managed" {
  for_each = local.user_secrets

  name         = each.key
  value        = ""
  env_slug     = var.environment_slug
  workspace_id = var.infisical_project_id
  folder_path  = each.value.folder

  depends_on = [infisical_secret_folder.this["terraform"]]

  lifecycle {
    ignore_changes  = [value]
    prevent_destroy = true
  }
}