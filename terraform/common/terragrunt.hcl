include "root" {
  path = find_in_parent_folders()
}

# common はシークレットを作る側なので data source 不要
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
  EOF
}
