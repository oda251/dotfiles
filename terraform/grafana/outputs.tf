output "stack_url" {
  description = "Grafana Cloud stack URL"
  value       = grafana_cloud_stack.this.url
}

output "otlp_endpoint" {
  description = "OTLP gateway endpoint"
  value       = local.otlp_endpoint
}
