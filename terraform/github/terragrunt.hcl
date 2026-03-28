include "root" {
  path = find_in_parent_folders()
}

inputs = {
  repositories = {
    dotfiles = {
      description = "chezmoi dotfiles"
      visibility  = "public"
    }
  }
}
