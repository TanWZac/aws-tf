SHELL := /bin/bash

ENV ?= dev
TF_DIR := .
VARS_FILE := environments/$(ENV)/terraform.tfvars
BACKEND_FILE := environments/$(ENV)/backend.hcl

.PHONY: help fmt init validate plan apply destroy lint security-check loadtest-smoke loadtest-spike org-init org-plan org-apply org-sync-accounts

help:
	@echo "Usage: make <target> ENV=<dev|stage|prod>"
	@echo "Targets: fmt, init, validate, plan, apply, destroy, lint, security-check"
	@echo "Load tests: loadtest-smoke BASE_URL=https://..., loadtest-spike BASE_URL=https://..."
	@echo "Org bootstrap (run once, from repo root): org-init, org-plan, org-apply, org-sync-accounts"

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

init:
	terraform -chdir=$(TF_DIR) init -backend-config=$(BACKEND_FILE)

validate:
	terraform -chdir=$(TF_DIR) validate

plan:
	terraform -chdir=$(TF_DIR) plan -var-file=$(VARS_FILE) -out=$(ENV).tfplan

apply:
	terraform -chdir=$(TF_DIR) apply $(ENV).tfplan

destroy:
	@[[ "$(CONFIRM)" == "yes" ]] || (echo "Destructive action: run with CONFIRM=yes to proceed"; exit 1)
	terraform -chdir=$(TF_DIR) destroy -var-file=$(VARS_FILE)

lint:
	tflint --init
	tflint --recursive

security-check:
	tfsec .
	checkov -d . --framework terraform

loadtest-smoke:
	@[[ -n "$(BASE_URL)" ]] || (echo "BASE_URL is required: make loadtest-smoke BASE_URL=https://..."; exit 1)
	k6 run -e BASE_URL=$(BASE_URL) loadtest/smoke.js

loadtest-spike:
	@[[ -n "$(BASE_URL)" ]] || (echo "BASE_URL is required: make loadtest-spike BASE_URL=https://..."; exit 1)
	k6 run -e BASE_URL=$(BASE_URL) loadtest/spike.js

# ── Org bootstrap (creates the Organization/OUs/accounts in org/) ────────────
# Separate from ENV-based targets above: run once from repo root, then again
# whenever account structure changes. See org/README.md.

org-init:
	terraform -chdir=org init

org-plan:
	terraform -chdir=org plan -var-file=terraform.tfvars

org-apply:
	terraform -chdir=org apply -var-file=terraform.tfvars

org-sync-accounts:
	terraform -chdir=org output -raw accounts_tf_content > accounts.tf
	@echo "accounts.tf regenerated from org/ outputs. Review the diff before committing."
