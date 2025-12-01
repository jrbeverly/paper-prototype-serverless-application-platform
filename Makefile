MANIFEST ?= app.yaml

.DEFAULT_GOAL := help

.PHONY: help validate build build-backend deploy

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

validate: ## Check Terraform formatting (terraform fmt -check)
	terraform fmt -check -recursive

build: ## Build application components
	npm --prefix frontend ci
	npm --prefix frontend run build
	$(MAKE) build-backend

build-backend: ## Build backend Lambda deployment package (backend/backend.zip)
	dotnet publish backend -c Release -r linux-x64 --self-contained false --output backend/.publish
	mv backend/.publish/Backend backend/.publish/bootstrap
	cd backend/.publish && zip -r ../backend.zip .
	rm -rf backend/.publish

deploy: ## Deploy the application
	MANIFEST="$(MANIFEST)" ./scripts/deploy.sh
