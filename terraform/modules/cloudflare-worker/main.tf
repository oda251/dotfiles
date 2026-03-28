terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0"
    }
  }
}

resource "cloudflare_workers_script" "this" {
  account_id          = var.account_id
  script_name         = var.name
  content             = var.content
  compatibility_date  = var.compatibility_date
  main_module         = "index.js"

  dynamic "bindings" {
    for_each = var.kv_bindings
    content {
      name         = bindings.key
      type         = "kv_namespace"
      namespace_id = bindings.value.namespace_id
    }
  }

  dynamic "bindings" {
    for_each = var.r2_bindings
    content {
      name        = bindings.key
      type        = "r2_bucket"
      bucket_name = bindings.value.bucket_name
    }
  }

  dynamic "bindings" {
    for_each = var.d1_bindings
    content {
      name        = bindings.key
      type        = "d1"
      database_id = bindings.value.database_id
    }
  }

  dynamic "bindings" {
    for_each = var.env_vars
    content {
      name = bindings.key
      type = "plain_text"
      text = bindings.value
    }
  }

  dynamic "bindings" {
    for_each = var.secret_vars
    content {
      name = bindings.key
      type = "secret_text"
      text = bindings.value
    }
  }
}

resource "cloudflare_workers_route" "this" {
  for_each = var.routes

  zone_id     = each.value.zone_id
  pattern     = each.key
  script_name = cloudflare_workers_script.this.script_name
}
