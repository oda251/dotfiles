variable "repositories" {
  description = "Map of repository name to config"
  type = map(object({
    description = optional(string, "")
    visibility  = optional(string, "public")
    topics      = optional(list(string), [])
    is_template = optional(bool, false)
    template    = optional(string, "template")
  }))
}

resource "github_repository" "this" {
  for_each = var.repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility
  topics      = each.value.topics
  is_template = each.value.is_template

  has_issues   = true
  has_projects = false
  has_wiki     = false

  delete_branch_on_merge = true
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = false

  dynamic "template" {
    for_each = each.value.is_template ? [] : [1]
    content {
      owner      = var.github_owner
      repository = each.value.template
    }
  }
}

resource "github_branch_protection" "main" {
  for_each = var.repositories

  repository_id = github_repository.this[each.key].node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  required_status_checks {
    strict = true
    contexts = ["ci"]
  }

  enforce_admins = true
}
