terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0"
    }
  }
}

resource "cloudflare_pages_project" "this" {
  account_id = var.account_id
  name       = var.name

  production_branch = var.production_branch

  build_config {
    build_command   = var.build_command
    destination_dir = var.destination_dir
  }

  deployment_configs {
    production {
      dynamic "environment_variables" {
        for_each = var.env_vars
        content {
          name  = environment_variables.key
          value = environment_variables.value
        }
      }
    }
  }
}
