# Import existing resources on first apply. Remove after successful import.

import {
  to = github_repository.this["dotfiles"]
  id = "dotfiles"
}

