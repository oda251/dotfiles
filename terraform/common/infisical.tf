# Infisical secret declarations
# TF ensures secrets exist; user fills in values via Infisical UI.

locals {
  root_folders = toset(["terraform", "generated"])
  sub_folders = {
    env   = { name = "env", path = "/terraform" }
    vars  = { name = "vars", path = "/terraform" }
    local = { name = "local", path = "/" }
  }

  # User-managed secrets: TF creates the entry, user sets the value.
  user_secrets = {
    # env category (Sync → HCP TF workspace env vars)
    GITHUB_PAT                             = { folder = "/terraform/env", comment = "GitHub Personal Access Token" }
    TF_API_TOKEN                           = { folder = "/terraform/env", comment = "Terraform Cloud API token" }
    TF_CLOUD_ORGANIZATION                  = { folder = "/terraform/env", comment = "Terraform Cloud organization name" }
    NEW_RELIC_API_KEY                      = { folder = "/terraform/env", comment = "New Relic User API key" }
    NEW_RELIC_ACCOUNT_ID                   = { folder = "/terraform/env", comment = "New Relic account ID" }
    INFISICAL_UNIVERSAL_AUTH_CLIENT_ID     = { folder = "/terraform/env", comment = "Infisical Universal Auth client ID" }
    INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET = { folder = "/terraform/env", comment = "Infisical Universal Auth client secret" }
    INFISICAL_PROJECT_SLUG                 = { folder = "/terraform/env", comment = "Infisical project slug (used by GHA secrets-action)" }
    SOPS_AGE_KEY                           = { folder = "/terraform/env", comment = "SOPS age private key (for decrypting private-repos.enc.yaml in CI)" }
    TF_VAR_infisical_project_id            = { folder = "/terraform/env", comment = "Infisical project UUID (as TF variable for local-exec runs)" }
    TF_VAR_environment_slug                = { folder = "/terraform/env", comment = "Infisical environment slug (as TF variable for local-exec runs)" }
    # terraform category (Sync → HCP TF workspace terraform vars)
    infisical_project_id = { folder = "/terraform/vars", comment = "Infisical project ID" }
    environment_slug     = { folder = "/terraform/vars", comment = "Infisical environment slug" }
    # SOPS age secret key
    SOPS_AGE_SECRET_KEY = { folder = "/local", comment = "SOPS age secret key for decrypting private-repos.enc.yaml" }
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
    ignore_changes = [value]
  }
}
