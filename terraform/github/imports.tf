# Import existing resources on first apply. Remove after successful import.

import {
  to = github_repository.this["garden"]
  id = "garden"
}

import {
  to = github_repository.this["sidekick"]
  id = "sidekick"
}

