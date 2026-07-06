# accounts.tf
# ─────────────────────────────────────────────────────────────────────────────
# Central registry of your AWS Organization structure.
#
# GENERATED FILE — do not hand-edit the id fields. This file is written by
# `make org-sync-accounts` (org/outputs.tf -> org/templates/accounts.tf.tpl).
# To change account structure, edit org/main.tf and re-run:
#   cd org && terraform apply && cd .. && make org-sync-accounts
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
# ─────────────────────────────────────────────────────────────────────────────

locals {

  # ── OU: Production ──────────────────────────────────────────────────────────
  ou_production = {
    account_a = {
      id     = "${account_a_id}"
      name   = "prod-primary"
      region = "${aws_region}"
    }
%{ if account_b_id != "" ~}
    account_b = {
      id     = "${account_b_id}"
      name   = "prod-secondary"
      region = "${aws_region}"
    }
%{ endif ~}
  }

  # ── OU: Development ─────────────────────────────────────────────────────────
  ou_development = {
    account_c = {
      id     = "${account_c_id}"
      name   = "dev"
      region = "${aws_region}"
    }
  }

  # ── OU: Staging ──────────────────────────────────────────────────────────────
  ou_staging = {
    account_stage = {
      id     = "${account_stage_id}"
      name   = "stage"
      region = "${aws_region}"
    }
  }

  # ── Derived ID lists ─────────────────────────────────────────────────────────
  prod_account_ids  = [for k, v in local.ou_production : v.id]
  dev_account_ids   = [for k, v in local.ou_development : v.id]
  stage_account_ids = [for k, v in local.ou_staging : v.id]

  # ── Environment → allowed account IDs ────────────────────────────────────────
  _env_account_ids = {
    prod  = local.prod_account_ids
    stage = local.stage_account_ids
    dev   = local.dev_account_ids
  }

  env_account_ids = lookup(local._env_account_ids, var.environment, [])
}
