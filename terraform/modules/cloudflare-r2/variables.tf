variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "name" {
  description = "R2 bucket name"
  type        = string
}

variable "location" {
  description = "Bucket location hint"
  type        = string
  default     = "APAC"
}
