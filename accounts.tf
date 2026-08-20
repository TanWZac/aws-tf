# accounts.tf
# ─────────────────────────────────────────────────────────────────────────────
# Central registry of your AWS Organization structure.
# Fill in your account IDs once here. The provider guardrail (allowed_account_ids)
# and any cross-account references are derived automatically from these locals.
#
# Structure mirrors your AWS Organizations hierarchy:
#
#   Organization
#   ├── OU: Production
#   │   ├── Account A  (primary production workload)
#   │   └── Account B  (secondary / DR production)
#   ├── OU: Development
#   │   └── Account C  (dev)
#   └── OU: Staging
#       └── Account Stage  (stage)
#
# Account IDs below are populated automatically by `org/` (see org/README.md)
# via `make org-sync-accounts`. Don't hand-edit the id fields once that's
# wired up — edits will be overwritten on the next sync.
# ─────────────────────────────────────────────────────────────────────────────

locals {

  # ── OU: Production ──────────────────────────────────────────────────────────
  ou_production = {
    account_a = {
      id     = "REPLACE_PROD_ACCOUNT_A_ID" # e.g. "111111111111"
      name   = "prod-primary"
      region = "us-east-1"
    }
    account_b = {
      id     = "REPLACE_PROD_ACCOUNT_B_ID" # e.g. "222222222222"
      name   = "prod-secondary"
      region = "us-east-1"
    }
  }

  # ── OU: Development ─────────────────────────────────────────────────────────
  ou_development = {
    account_c = {
      id     = "REPLACE_DEV_ACCOUNT_C_ID" # e.g. "333333333333"
      name   = "dev"
      region = "us-east-1"
    }
  }

  # ── OU: Staging ──────────────────────────────────────────────────────────────
  ou_staging = {
    account_stage = {
      id     = "REPLACE_STAGE_ACCOUNT_ID" # e.g. "444444444444"
      name   = "stage"
      region = "us-east-1"
    }
  }

  # ── Derived ID lists ─────────────────────────────────────────────────────────
  prod_account_ids  = [for k, v in local.ou_production : v.id]
  dev_account_ids   = [for k, v in local.ou_development : v.id]
  stage_account_ids = [for k, v in local.ou_staging : v.id]

  # ── Environment → allowed account IDs ────────────────────────────────────────
  # Controls which account IDs the AWS provider will accept for each environment.
  # Each environment now maps to its own OU/account — stage no longer falls
  # back to the prod account IDs.
  _env_account_ids = {
    prod  = local.prod_account_ids
    stage = local.stage_account_ids
    dev   = local.dev_account_ids
  }

  # Resolved for the current var.environment. Do not fall back to []: an empty
  # allowed_account_ids disables the account guardrail exactly when it is needed.
  env_account_ids = local._env_account_ids[var.environment]
}
