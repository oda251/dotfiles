include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "common" {
  config_path  = "../common"
  skip_outputs = true
}

inputs = {
  github_owner            = "oda251"
  infisical_client_id     = get_env("INFISICAL_UNIVERSAL_AUTH_CLIENT_ID", "")
  infisical_client_secret = get_env("INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET", "")
  repositories = {
    dotfiles = {
      description   = "chezmoi dotfiles"
      visibility    = "public"
      has_terraform = true
    }
  }
}
