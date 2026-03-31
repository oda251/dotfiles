SHELL := /bin/bash
.PHONY: help tf-init tf-plan tf-apply tf-fmt sync-configs cleanup

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================
# Terraform
# =============================================

tf-init: ## Interactive bootstrap: Infisical setup → common → fill secrets → all stacks
	scripts/tf-init.sh

tf-plan: ## Run terragrunt plan on all stacks
	scripts/tf-plan.sh

tf-apply: ## Run terragrunt apply on all stacks
	scripts/tf-apply.sh

tf-fmt: ## Format all terraform files
	scripts/tf-fmt.sh

# =============================================
# Dotfiles
# =============================================

sync-configs: ## Distribute AI agent configs
	scripts/distribute_ai_agent_configs.sh

cleanup: ## Clean up brew, mise, npm caches
	scripts/cleanup.sh
