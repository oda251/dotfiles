variable "repositories" {
  description = "Map of repository name to config"
  type = map(object({
    description       = optional(string, "")
    visibility        = optional(string, "public")
    topics            = optional(list(string), [])
    is_template       = optional(bool, false)
    template          = optional(string)
    has_terraform = optional(bool, false) # true なら TF workflow を配置
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
    for_each = each.value.template != null ? [1] : []
    content {
      owner      = var.github_owner
      repository = each.value.template
    }
  }
}

resource "github_repository_file" "terraform_workflow" {
  for_each = { for k, v in var.repositories : k => v if v.has_terraform }

  repository = github_repository.this[each.key].name
  branch     = "main"
  file       = ".github/workflows/terraform.yml"
  content    = templatefile("${path.module}/templates/terraform.yml.tpl", {
    gate_needs = ["plan"]
  })
  commit_message      = "chore: update Terraform workflow (managed by Terraform)"
  overwrite_on_create = true

  lifecycle {
    ignore_changes = [content]
  }
}

resource "github_repository_ruleset" "main" {
  for_each = var.repositories

  depends_on  = [github_repository_file.terraform_workflow]
  repository  = github_repository.this[each.key].name
  name        = "main"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count = 0
      dismiss_stale_reviews_on_push   = true
    }

    dynamic "required_status_checks" {
      for_each = each.value.has_terraform ? [1] : []
      content {
        required_check {
          context = "gate"
        }
        strict_required_status_checks_policy = true
      }
    }
  }
}
