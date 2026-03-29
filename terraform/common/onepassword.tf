# 1Password item declarations
# TF ensures items exist; user fills in values via 1Password UI.

resource "onepassword_item" "github_pat" {
  vault = var.op_vault_id
  title = "github-pat"

  lifecycle {
    ignore_changes = [password]
  }
}

resource "onepassword_item" "terraform_cloud" {
  vault = var.op_vault_id
  title = "terraform-cloud"

  section {
    label = "Terraform Cloud"

    field {
      label = "organization"
      value = ""
      type  = "CONCEALED"
    }
  }

  lifecycle {
    ignore_changes = [password, section]
  }
}

resource "onepassword_item" "grafana_cloud" {
  vault = var.op_vault_id
  title = "grafana-cloud"

  section {
    label = "API"

    field {
      label = "api-key"
      value = ""
      type  = "CONCEALED"
    }
  }

  lifecycle {
    ignore_changes = [section]
  }
}

resource "onepassword_item" "onepassword_sa" {
  vault = var.op_vault_id
  title = "1password-sa"

  section {
    label = "Service Account"

    field {
      label = "credential"
      value = ""
      type  = "CONCEALED"
    }

    field {
      label = "vault-id"
      value = ""
      type  = "CONCEALED"
    }
  }

  lifecycle {
    ignore_changes = [section]
  }
}
