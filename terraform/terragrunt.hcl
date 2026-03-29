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
  EOF
}
