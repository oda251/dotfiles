include "root" {
  path = find_in_parent_folders()
}

inputs = {
  github_owner = "oda251"
  repositories = {
    dotfiles = {
      description   = "chezmoi dotfiles"
      visibility    = "public"
      has_terraform = true
    }
  }
}
