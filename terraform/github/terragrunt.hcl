include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "common" {
  config_path  = "../common"
  skip_outputs = true
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
    sidekick = {
      visibility    = "public"
      has_infisical = true
    }
  }
}
