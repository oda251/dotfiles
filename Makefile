SHELL := /bin/bash
.PHONY: help sync-configs cleanup

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================
# Dotfiles
# =============================================

sync-configs: ## Distribute AI agent configs
	scripts/distribute_ai_agent_configs.sh

cleanup: ## Clean up brew, mise, npm caches
	scripts/cleanup.sh
