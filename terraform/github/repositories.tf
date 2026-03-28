variable "repositories" {
  description = "Map of repository name to config"
  type = map(object({
    description = optional(string, "")
    visibility  = optional(string, "public")
    topics      = optional(list(string), [])
    is_template = optional(bool, false)
    template          = optional(string)
    branch_protection = optional(bool, true)         # true: 直プッシュ不可+CI必須, false: 直プッシュOK
    terraform_stacks  = optional(list(string), [])   # e.g. ["terraform/app"] — 空なら TF workflow を配置しない
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
  for_each = { for k, v in var.repositories : k => v if length(v.terraform_stacks) > 0 }

  repository = github_repository.this[each.key].name
  branch     = "main"
  file       = ".github/workflows/terraform.yml"
  content = templatefile("${path.module}/templates/terraform.yml.tpl", {
    stacks = each.value.terraform_stacks
  })
  commit_message      = "chore: update Terraform workflow (managed by Terraform)"
  overwrite_on_create = true
}

resource "github_branch_protection" "main" {
  for_each = { for k, v in var.repositories : k => v if v.branch_protection }

  depends_on    = [github_repository_file.terraform_workflow]
  repository_id = github_repository.this[each.key].node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
    dismiss_stale_reviews           = true
  }

  required_status_checks {
    strict   = true
    contexts = length(each.value.terraform_stacks) > 0 ? [
      for s in each.value.terraform_stacks : "plan-${replace(s, "/", "-")}"
    ] : []
  }

  enforce_admins = true
}
