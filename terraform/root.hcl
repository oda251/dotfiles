generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      cloud {
        workspaces {
          name = "${basename(get_terragrunt_dir())}"
        }
      }
    }
  EOF
}

generate "infisical" {
  path      = "provider_infisical.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "infisical" {
      host = "https://app.infisical.com"
    }

    variable "infisical_project_id" {
      description = "Infisical project ID"
      type        = string
    }

    variable "environment_slug" {
      description = "Infisical environment slug"
      type        = string
    }

    data "infisical_secrets" "terraform" {
      env_slug     = var.environment_slug
      workspace_id = var.infisical_project_id
      folder_path  = "/terraform"
    }
  EOF
}

inputs = {
  infisical_project_id     = get_env("TF_VAR_infisical_project_id", "")
  infisical_ci_identity_id = get_env("TF_VAR_infisical_ci_identity_id", "")
  environment_slug         = "prod"
}
