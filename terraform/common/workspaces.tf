locals {
  workspaces = toset(["common", "github", "newrelic"])
}

data "tfe_workspace" "all" {
  for_each     = local.workspaces
  name         = each.value
  organization = var.tfe_organization
}

resource "tfe_workspace_settings" "all" {
  for_each       = data.tfe_workspace.all
  workspace_id   = each.value.id
  execution_mode = "local"
}

variable "tfe_organization" {
  description = "Terraform Cloud organization name"
  type        = string
}
