terraform {
  required_version = ">= 1.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.0"
    }
  }
}

provider "grafana" {
  cloud_access_policy_token = var.grafana_cloud_api_key
}

provider "onepassword" {
  service_account_token = var.op_service_account_token
}

variable "op_service_account_token" {
  description = "1Password service account token"
  type        = string
  sensitive   = true
}

variable "op_vault_id" {
  description = "1Password vault ID for storing secrets"
  type        = string
}

variable "grafana_cloud_api_key" {
  description = "Grafana Cloud API key (org-level)"
  type        = string
  sensitive   = true
}

variable "grafana_stack_slug" {
  description = "Grafana Cloud stack slug"
  type        = string
}

variable "grafana_stack_region" {
  description = "Grafana Cloud stack region"
  type        = string
  default     = "ap-northeast-0"
}
