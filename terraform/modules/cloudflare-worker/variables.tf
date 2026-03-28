variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "name" {
  description = "Worker script name"
  type        = string
}

variable "content" {
  description = "Worker script content (file path)"
  type        = string
}

variable "compatibility_date" {
  description = "Workers compatibility date"
  type        = string
  default     = "2024-01-01"
}

variable "routes" {
  description = "Map of route pattern to zone_id"
  type = map(object({
    zone_id = string
  }))
  default = {}
}

variable "kv_bindings" {
  description = "KV namespace bindings"
  type = map(object({
    namespace_id = string
  }))
  default = {}
}

variable "r2_bindings" {
  description = "R2 bucket bindings"
  type = map(object({
    bucket_name = string
  }))
  default = {}
}

variable "d1_bindings" {
  description = "D1 database bindings"
  type = map(object({
    database_id = string
  }))
  default = {}
}

variable "env_vars" {
  description = "Plain text environment variables"
  type        = map(string)
  default     = {}
}

variable "secret_vars" {
  description = "Secret environment variables"
  type        = map(string)
  default     = {}
  sensitive   = true
}
