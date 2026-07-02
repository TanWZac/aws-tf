SHELL := /bin/bash

ENV ?= dev
TF_DIR := .
VARS_FILE := environments/$(ENV)/terraform.tfvars
BACKEND_FILE := environments/$(ENV)/backend.hcl

.PHONY: help fmt init validate plan apply destroy

help:
	@echo "Usage: make <target> ENV=<dev|stage|prod>"
	@echo "Targets: fmt, init, validate, plan, apply, destroy"

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
	terraform -chdir=$(TF_DIR) destroy -var-file=$(VARS_FILE)
