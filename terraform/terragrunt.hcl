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

generate "bitwarden" {
  path      = "provider_bitwarden.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "bitwarden" {
      email           = var.bw_email
      master_password = var.bw_master_password
      server          = "https://vault.bitwarden.com"
    }

    variable "bw_email" {
      description = "Bitwarden account email"
      type        = string
    }

    variable "bw_master_password" {
      description = "Bitwarden master password"
      type        = string
      sensitive   = true
    }
  EOF
}
