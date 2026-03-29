# Instance-level provider for managing dashboards and data sources
provider "grafana" {
  alias = "instance"
  url   = grafana_cloud_stack.this.url
  auth  = grafana_cloud_stack_service_account_token.dashboard_admin.key
}

resource "grafana_cloud_stack_service_account" "dashboard_admin" {
  stack_slug = grafana_cloud_stack.this.slug
  name       = "terraform-dashboard-admin"
  role       = "Admin"
}

resource "grafana_cloud_stack_service_account_token" "dashboard_admin" {
  stack_slug         = grafana_cloud_stack.this.slug
  name               = "terraform"
  service_account_id = grafana_cloud_stack_service_account.dashboard_admin.id
}

resource "grafana_folder" "claude_code" {
  provider = grafana.instance
  title    = "Claude Code"
}

resource "grafana_dashboard" "claude_code_overview" {
  provider    = grafana.instance
  folder      = grafana_folder.claude_code.id
  config_json = file("${path.module}/dashboards/claude-code-overview.json")
}
