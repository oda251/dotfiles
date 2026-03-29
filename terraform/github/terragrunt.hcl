include "root" {
  path = find_in_parent_folders()
}

dependency "common" {
  config_path = "../common"
}

inputs = {
  github_owner            = "oda251"
  infisical_client_id     = dependency.common.outputs.github_actions_client_id
  infisical_client_secret = dependency.common.outputs.github_actions_client_secret
  repositories = {
    dotfiles = {
      description   = "chezmoi dotfiles"
      visibility    = "public"
      has_terraform = true
    }
  }
}
