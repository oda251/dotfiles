# Infisical secret declarations
# TF ensures secrets exist; user fills in values via Infisical UI.

locals {
  root_folders = toset(["terraform", "generated"])
  sub_folders = {
    env  = { name = "env", path = "/terraform" }
    vars = { name = "vars", path = "/terraform" }
  }

  # User-managed secrets: TF creates the entry, user sets the value.
  user_secrets = {
    # env category (Sync → HCP TF workspace env vars)
    GITHUB_PAT                             = { folder = "/terraform/env", comment = "GitHub Personal Access Token" }
    TF_API_TOKEN                           = { folder = "/terraform/env", comment = "Terraform Cloud API token" }
    TF_CLOUD_ORGANIZATION                  = { folder = "/terraform/env", comment = "Terraform Cloud organization name" }
    NEW_RELIC_API_KEY                      = { folder = "/terraform/env", comment = "New Relic User API key" }
    NEW_RELIC_ACCOUNT_ID                   = { folder = "/terraform/env", comment = "New Relic account ID" }
    NPM_TOKEN                              = { folder = "/terraform/env", comment = "npm publish token" }
    INFISICAL_UNIVERSAL_AUTH_CLIENT_ID     = { folder = "/terraform/env", comment = "Infisical Universal Auth client ID" }
    INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET = { folder = "/terraform/env", comment = "Infisical Universal Auth client secret" }
    # terraform category (Sync → HCP TF workspace terraform vars)
    infisical_project_id = { folder = "/terraform/vars", comment = "Infisical project ID" }
    environment_slug     = { folder = "/terraform/vars", comment = "Infisical environment slug" }
  }
}


resource "infisical_secret_folder" "root" {
  for_each = local.root_folders

  name             = each.value
  environment_slug = var.environment_slug
  project_id       = var.infisical_project_id
  folder_path      = "/"
}

resource "infisical_secret_folder" "sub" {
  for_each = local.sub_folders

  name             = each.value.name
  environment_slug = var.environment_slug
  project_id       = var.infisical_project_id
  folder_path      = each.value.path

  depends_on = [infisical_secret_folder.root]
}


resource "infisical_secret" "user_managed" {
  for_each = local.user_secrets

  name         = each.key
  value        = ""
  env_slug     = var.environment_slug
  workspace_id = var.infisical_project_id
  folder_path  = each.value.folder

  depends_on = [infisical_secret_folder.root, infisical_secret_folder.sub]

  lifecycle {
    ignore_changes  = [value]
    prevent_destroy = true
  }
}
