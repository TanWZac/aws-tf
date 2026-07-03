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
#   └── OU: Development
#       └── Account C  (dev + staging shared, or split below)
# ─────────────────────────────────────────────────────────────────────────────

locals {

  # ── OU: Production ──────────────────────────────────────────────────────────
  ou_production = {
    account_a = {
      id     = "REPLACE_PROD_ACCOUNT_A_ID"  # e.g. "111111111111"
      name   = "prod-primary"
      region = "us-east-1"
    }
    account_b = {
      id     = "REPLACE_PROD_ACCOUNT_B_ID"  # e.g. "222222222222"
      name   = "prod-secondary"
      region = "us-east-1"
    }
  }

  # ── OU: Development ─────────────────────────────────────────────────────────
  ou_development = {
    account_c = {
      id     = "REPLACE_DEV_ACCOUNT_C_ID"   # e.g. "333333333333"
      name   = "dev"
      region = "us-east-1"
    }
  }

  # ── Optional: separate staging OU / account ──────────────────────────────────
  # Uncomment and populate if staging lives in its own account.
  # ou_staging = {
  #   account_stage = {
  #     id     = "REPLACE_STAGE_ACCOUNT_ID"
  #     name   = "stage"
  #     region = "us-east-1"
  #   }
  # }

  # ── Derived ID lists ─────────────────────────────────────────────────────────
  prod_account_ids  = [for k, v in local.ou_production : v.id]
  dev_account_ids   = [for k, v in local.ou_development : v.id]
  # stage_account_ids = [for k, v in local.ou_staging : v.id]  # uncomment when staging OU is defined

  # ── Environment → allowed account IDs ────────────────────────────────────────
  # Controls which account IDs the AWS provider will accept for each environment.
  # Adjust the mapping if staging lives in its own account.
  _env_account_ids = {
    prod  = local.prod_account_ids
    stage = local.prod_account_ids  # TODO: change to local.stage_account_ids if staging has its own account — currently staging targets prod accounts
    dev   = local.dev_account_ids
  }

  # Resolved for the current var.environment. Falls back to [] (no guardrail)
  # if a matching entry is not found, preserving backward-compatible behaviour.
  env_account_ids = lookup(local._env_account_ids, var.environment, [])
}
