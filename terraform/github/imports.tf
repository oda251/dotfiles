# Import existing resources on first apply. Remove after successful import.

import {
  to = github_repository.this["dotfiles"]
  id = "dotfiles"
}

import {
  to = github_branch_protection.main["dotfiles"]
  id = "dotfiles:main"
}
