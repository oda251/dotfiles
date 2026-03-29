SHELL := /bin/bash
.PHONY: help tf-init tf-plan tf-apply tf-fmt sync-configs cleanup

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================
# Terraform
# =============================================

tf-init: ## Initial setup: common → user fills Infisical values → all stacks
	cd terraform/common && source ../.env.infisical && terragrunt apply
	@echo "\nInfisical Web UI で各シークレットに値を設定してから Enter を押してください"
	@read _
	cd terraform && source .env.infisical && terragrunt run-all apply

tf-plan: ## Run terragrunt plan on all stacks
	cd terraform && source .env.infisical && terragrunt run-all plan

tf-apply: ## Run terragrunt apply on all stacks
	cd terraform && source .env.infisical && terragrunt run-all apply

tf-fmt: ## Format all terraform files
	terraform fmt -recursive terraform/

# =============================================
# Dotfiles
# =============================================

sync-configs: ## Distribute AI agent configs
	scripts/distribute_ai_agent_configs.sh

cleanup: ## Clean up brew, mise, npm caches
	scripts/cleanup.sh
