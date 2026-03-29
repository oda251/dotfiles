# Bitwarden item declarations
# TF ensures items exist; user fills in values via Bitwarden UI.

variable "bw_organization_id" {
  description = "Bitwarden organization ID (optional)"
  type        = string
  default     = null
}

resource "bitwarden_item_login" "github_pat" {
  name     = "github-pat"
  username = ""

  lifecycle {
    ignore_changes = [username, password]
  }
}

resource "bitwarden_item_login" "terraform_cloud" {
  name     = "terraform-cloud"
  username = ""

  field {
    name = "organization"
    text = ""
  }

  lifecycle {
    ignore_changes = [username, password, field]
  }
}

resource "bitwarden_item_login" "grafana_cloud" {
  name     = "grafana-cloud"
  username = ""

  field {
    name = "api-key"
    text = ""
  }

  lifecycle {
    ignore_changes = [username, password, field]
  }
}
