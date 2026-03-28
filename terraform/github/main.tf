terraform {
  required_version = ">= 1.0"

  cloud {
    workspaces {
      name = "github"
    }
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
}

variable "github_owner" {
  description = "GitHub organization or user"
  type        = string
}
