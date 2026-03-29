SHELL := /bin/bash
.PHONY: help tf-init tf-plan tf-apply tf-fmt sync-configs cleanup

ENV_FILE := terraform/.env.infisical

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================
# Terraform
# =============================================

tf-init: ## Interactive bootstrap: Infisical setup → common → fill secrets → all stacks
	@echo "=== Infisical Bootstrap ==="
	@echo ""
	@command -v infisical >/dev/null 2>&1 || { echo "ERROR: infisical CLI が見つかりません。mise install を実行してください。"; exit 1; }
	@command -v terragrunt >/dev/null 2>&1 || { echo "ERROR: terragrunt が見つかりません。"; exit 1; }
	@echo "1) https://app.infisical.com でアカウント・プロジェクトを作成"
	@echo "2) Settings > Machine Identities で Universal Auth の Identity を作成"
	@echo "3) 作成した Identity にプロジェクトへのアクセス権を付与"
	@echo ""
	@read -p "Organization ID: " org_id && \
	 read -p "Project ID: " project_id && \
	 read -p "Client ID: " client_id && \
	 read -sp "Client Secret: " client_secret && echo "" && \
	 printf 'export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=%s\nexport INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=%s\nexport INFISICAL_ORG_ID=%s\nexport TF_VAR_infisical_project_id=%s\n' \
	   "$$client_id" "$$client_secret" "$$org_id" "$$project_id" > $(ENV_FILE) && \
	 echo "" && echo "$(ENV_FILE) を書き込みました。"
	@echo ""
	@echo "=== common スタック apply (シークレット枠を作成) ==="
	cd terraform/common && source ../$(notdir $(ENV_FILE)) && terragrunt apply
	@echo ""
	@echo "=== Infisical Web UI で /terraform フォルダ内のシークレットに値を設定してください ==="
	@echo "  - GITHUB_PAT        : GitHub Personal Access Token"
	@echo "  - TF_API_TOKEN      : Terraform Cloud API token"
	@echo "  - TF_CLOUD_ORG      : Terraform Cloud organization 名"
	@echo "  - GRAFANA_API_KEY   : Grafana Cloud org-level API key"
	@echo ""
	@read -p "設定完了したら Enter を押してください..."
	@echo ""
	@echo "=== 全スタック apply ==="
	cd terraform && source $(notdir $(ENV_FILE)) && terragrunt run-all apply
	@echo ""
	@echo "=== Bootstrap 完了 ==="
	@echo "以降は make tf-apply で全スタックを更新できます。"

tf-plan: ## Run terragrunt plan on all stacks
	cd terraform && source $(notdir $(ENV_FILE)) && terragrunt run-all plan

tf-apply: ## Run terragrunt apply on all stacks
	cd terraform && source $(notdir $(ENV_FILE)) && terragrunt run-all apply

tf-fmt: ## Format all terraform files
	terraform fmt -recursive terraform/

# =============================================
# Dotfiles
# =============================================

sync-configs: ## Distribute AI agent configs
	scripts/distribute_ai_agent_configs.sh

cleanup: ## Clean up brew, mise, npm caches
	scripts/cleanup.sh
