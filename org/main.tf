# org/main.tf
# ─────────────────────────────────────────────────────────────────────────────
# Creates the AWS Organization, OU structure, and member accounts referenced
# by root accounts.tf. Run this from the MANAGEMENT (payer) account — it is
# intentionally a separate state/module from the rest of the repo, since org
# management and workload deployment should carry different blast radius and
# different credentials.
#
# Usage:
#   cd org
#   terraform init          # local state — bootstrap this one like bootstrap/
#   terraform apply -var-file=terraform.tfvars
#   cd ..
#   make org-sync-accounts  # writes real account IDs into root accounts.tf
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  profile             = var.aws_profile
  allowed_account_ids = [var.management_account_id]
}

# ── Organization ───────────────────────────────────────────────────────────────
# If Organizations is already enabled on this account (e.g. via console),
# import instead: terraform import aws_organizations_organization.this <org-id>

resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]

  feature_set = "ALL" # required for SCPs
}

# ── Organizational Units ────────────────────────────────────────────────────────
# Mirrors the OU names used in root accounts.tf (Production, Development, Staging)
# plus a Security OU for log-archive/tooling accounts that aren't a deploy target.

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "development" {
  name      = "Development"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "staging" {
  name      = "Staging"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

# ── Security/tooling accounts ───────────────────────────────────────────────────
# Not referenced in root accounts.tf (they're not a deploy target for the
# platform repo) — used for CloudTrail log aggregation and security tooling.

resource "aws_organizations_account" "log_archive" {
  name      = "${var.project_name}-log-archive"
  email     = var.log_archive_account_email
  parent_id = aws_organizations_organizational_unit.security.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "security_tooling" {
  name      = "${var.project_name}-security-tooling"
  email     = var.security_account_email
  parent_id = aws_organizations_organizational_unit.security.id

  lifecycle {
    prevent_destroy = true
  }
}

# ── Workload accounts ───────────────────────────────────────────────────────────
# These map 1:1 to root accounts.tf: account_a/account_b (Production),
# account_c (Development), account_stage (Staging).

resource "aws_organizations_account" "prod_primary" {
  name      = "${var.project_name}-prod-primary"
  email     = var.prod_primary_account_email
  parent_id = aws_organizations_organizational_unit.production.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "prod_secondary" {
  count = var.enable_prod_secondary ? 1 : 0

  name      = "${var.project_name}-prod-secondary"
  email     = var.prod_secondary_account_email
  parent_id = aws_organizations_organizational_unit.production.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "dev" {
  name      = "${var.project_name}-dev"
  email     = var.dev_account_email
  parent_id = aws_organizations_organizational_unit.development.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "stage" {
  name      = "${var.project_name}-stage"
  email     = var.stage_account_email
  parent_id = aws_organizations_organizational_unit.staging.id

  lifecycle {
    prevent_destroy = true
  }
}
