resource "grafana_cloud_stack" "this" {
  name        = var.grafana_stack_slug
  slug        = var.grafana_stack_slug
  region_slug = var.grafana_stack_region
}

resource "grafana_cloud_access_policy" "otlp_write" {
  name         = "otlp-write"
  display_name = "OTLP Write Access"
  region       = var.grafana_stack_region

  dynamic "scopes" {
    for_each = toset(["metrics:write", "logs:write", "traces:write"])
    content {
      action = scopes.value
      realm {
        type       = "stack"
        identifier = grafana_cloud_stack.this.id
      }
    }
  }
}

resource "grafana_cloud_access_policy_token" "otlp_write" {
  name             = "otlp-write-token"
  access_policy_id = grafana_cloud_access_policy.otlp_write.policy_id
  region           = var.grafana_stack_region
}

locals {
  otlp_endpoint = "https://otlp-gateway-${var.grafana_stack_region}.grafana.net/otlp"
  otlp_token    = grafana_cloud_access_policy_token.otlp_write.token
  # Basic auth: instance_id:token
  otlp_basic_auth = base64encode("${grafana_cloud_stack.this.id}:${local.otlp_token}")
}
