.PHONY: help tf-plan tf-apply tf-apply-all tf-plan-all tf-fmt tf-common tf-github tf-grafana sync-configs cleanup

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================
# Terraform
# =============================================

tf-plan-all: ## Run terragrunt plan on all stacks
	cd terraform && op run --env-file=.env.op -- terragrunt run-all plan

tf-apply-all: ## Run terragrunt apply on all stacks
	cd terraform && op run --env-file=.env.op -- terragrunt run-all apply

tf-common: ## Apply common stack (1Password items)
	cd terraform/common && op run --env-file=../.env.op -- terragrunt apply

tf-github: ## Apply github stack
	cd terraform/github && op run --env-file=../.env.op -- terragrunt apply

tf-grafana: ## Apply grafana stack
	cd terraform/grafana && op run --env-file=../.env.op -- terragrunt apply

tf-fmt: ## Format all terraform files
	terraform fmt -recursive terraform/

# =============================================
# Dotfiles
# =============================================

sync-configs: ## Distribute AI agent configs
	scripts/distribute_ai_agent_configs.sh

cleanup: ## Clean up brew, mise, npm caches
	scripts/cleanup.sh
