include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "common" {
  config_path  = "../common"
  skip_outputs = true
}

locals {
  private = yamldecode(sops_decrypt_file("${get_terragrunt_dir()}/private-repos.enc.yaml"))
}

inputs = {
  github_owner = "oda251"
  repositories = {
    dotfiles = {
      description   = "chezmoi dotfiles"
      visibility    = "public"
      has_infisical = true
      has_terraform = true
    }
    garden = {
      visibility    = "public"
      has_infisical = true
      has_terraform = true
    }
    onegai = {
      visibility    = "public"
      has_infisical = true
    }
  }
  private_repositories = local.private.repositories
}
