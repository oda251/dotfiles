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

generate "onepassword" {
  path      = "provider_onepassword.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "onepassword" {
      service_account_token = var.op_service_account_token
    }

    variable "op_service_account_token" {
      description = "1Password service account token"
      type        = string
      sensitive   = true
    }

    variable "op_vault_id" {
      description = "1Password vault ID for storing secrets"
      type        = string
    }
  EOF
}
