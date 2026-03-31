# TF-managed: OTLP credentials for New Relic, stored in Infisical.

locals {
  otlp_endpoint = var.newrelic_region == "EU" ? "https://otlp.eu01.nr-data.net:4318" : "https://otlp.nr-data.net:4318"

  generated_secrets = {
    NEWRELIC_OTLP_ENDPOINT = { value = local.otlp_endpoint, comment = "New Relic OTLP endpoint" }
    NEWRELIC_LICENSE_KEY   = { value = newrelic_api_access_key.ingest.key, comment = "New Relic Ingest License Key for OTLP" }
  }
}

resource "newrelic_api_access_key" "ingest" {
  account_id  = data.infisical_secrets.terraform.secrets["NEW_RELIC_ACCOUNT_ID"].value
  key_type    = "INGEST"
  ingest_type = "LICENSE"
  name        = "otlp-ingest"
  notes       = "Managed by Terraform – OTLP telemetry ingestion"
}

resource "infisical_secret" "generated" {
  for_each = local.generated_secrets

  name         = each.key
  value        = each.value.value
  comment      = each.value.comment
  env_slug     = var.env_slug
  workspace_id = var.infisical_project_id
  folder_path  = "/generated"
}
