variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "name" {
  description = "Pages project name"
  type        = string
}

variable "production_branch" {
  description = "Branch for production deployments"
  type        = string
  default     = "main"
}

variable "build_command" {
  description = "Build command"
  type        = string
  default     = "make build"
}

variable "destination_dir" {
  description = "Build output directory"
  type        = string
  default     = "dist"
}

variable "env_vars" {
  description = "Environment variables for build"
  type        = map(string)
  default     = {}
}
