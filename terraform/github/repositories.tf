variable "repositories" {
  description = "Map of repository name to config"
  type = map(object({
    description   = optional(string, "")
    visibility    = optional(string, "public")
    topics        = optional(list(string), [])
    is_template   = optional(bool, false)
    template      = optional(string)
    has_infisical = optional(bool, false) # true なら Infisical credentials を配布
    has_terraform = optional(bool, false) # true なら TF workflow を配置
  }))
}

variable "private_repositories" {
  description = "Map of private repository name to config (from SOPS)"
  type = map(object({
    description   = optional(string, "")
    topics        = optional(list(string), [])
    is_template   = optional(bool, false)
    template      = optional(string)
    has_infisical = optional(bool, false)
    has_terraform = optional(bool, false)
  }))
  default = {}
}

locals {
  private_repos    = { for k, v in var.private_repositories : k => merge(v, { visibility = "private" }) }
  all_repositories = merge(var.repositories, local.private_repos)
}

resource "github_repository" "this" {
  for_each = local.all_repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility
  topics      = each.value.topics
  is_template = each.value.is_template

  has_issues   = true
  has_projects = false
  has_wiki     = false

  vulnerability_alerts = true

  dynamic "security_and_analysis" {
    for_each = each.value.visibility == "public" ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

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

locals {
  workflows = merge(
    { for k, v in local.all_repositories : "${k}/gate" => {
      repo = k, file = "gate.yml", message = "chore: add gate workflow (managed by Terraform)"
    } if v.visibility != "private" },
    { for k, v in local.all_repositories : "${k}/terraform" => {
      repo = k, file = "terraform.yml", message = "chore: update Terraform workflow (managed by Terraform)"
    } if v.has_terraform },
  )
}

resource "github_repository_file" "workflow" {
  for_each = local.workflows

  repository          = github_repository.this[each.value.repo].name
  branch              = "main"
  file                = ".github/workflows/${each.value.file}"
  content             = templatefile("${path.module}/templates/${each.value.file}.tpl", {})
  commit_message      = each.value.message
  overwrite_on_create = true

  lifecycle {
    ignore_changes = [content]
  }
}

resource "github_repository_ruleset" "main" {
  for_each = { for k, v in local.all_repositories : k => v if v.visibility != "private" }

  repository  = github_repository.this[each.key].name
  name        = "main"
  target      = "branch"
  enforcement = "active"

  bypass_actors {
    actor_id    = 5 # Repository admin
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
    }

    required_status_checks {
      required_check {
        context = "gate"
      }
      strict_required_status_checks_policy = true
    }
  }
}
