include "root" {
  path           = find_in_parent_folders("root.hcl")
  expose         = true
  merge_strategy = "deep"
}

# common はシークレットを作る側なので data source を除外してオーバーライド
generate "infisical" {
  path              = "provider_infisical.tf"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
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
