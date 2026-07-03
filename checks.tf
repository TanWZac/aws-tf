# checks.tf
# ─────────────────────────────────────────────────────────────────────────────
# Terraform check blocks (requires Terraform >= 1.5).
# These are non-blocking assertions that warn during plan/apply when the
# workspace is in a state that violates an expectation.
#
# Unlike variable validations (which fail the plan), checks emit warnings
# and allow the operator to make an informed decision.
# ─────────────────────────────────────────────────────────────────────────────

# ── Account ID placeholders ───────────────────────────────────────────────────

check "no_placeholder_account_ids" {
  assert {
    condition = alltrue([
      for id in local.env_account_ids : !startswith(id, "REPLACE_")
    ])
    error_message = "One or more AWS account IDs in accounts.tf contain placeholder values (REPLACE_*). Update them before deploying to production."
  }
}

# ── Capacity relationship ─────────────────────────────────────────────────────

check "capacity_relationship" {
  assert {
    condition     = var.app_desired_count >= var.app_min_capacity && var.app_desired_count <= var.app_max_capacity
    error_message = "app_desired_count (${var.app_desired_count}) must be between app_min_capacity (${var.app_min_capacity}) and app_max_capacity (${var.app_max_capacity})."
  }
}

check "min_max_capacity_order" {
  assert {
    condition     = var.app_min_capacity <= var.app_max_capacity
    error_message = "app_min_capacity (${var.app_min_capacity}) must not exceed app_max_capacity (${var.app_max_capacity})."
  }
}

# ── Production safety guards ──────────────────────────────────────────────────

check "prod_requires_https" {
  assert {
    condition     = var.environment != "prod" || var.enable_alb_https
    error_message = "Production environment should have enable_alb_https = true. Plain HTTP in production exposes traffic."
  }
}

check "prod_requires_waf" {
  assert {
    condition     = var.environment != "prod" || var.enable_waf
    error_message = "Production environment should have enable_waf = true."
  }
}

check "prod_requires_deletion_protection" {
  assert {
    condition     = var.environment != "prod" || var.enable_alb_deletion_protection
    error_message = "Production environment should have enable_alb_deletion_protection = true."
  }
}

check "prod_nat_mode" {
  assert {
    condition     = var.environment != "prod" || var.nat_gateway_mode == "per_az"
    error_message = "Production environment should use nat_gateway_mode = \"per_az\" for high availability."
  }
}

check "prod_min_task_count" {
  assert {
    condition     = var.environment != "prod" || var.app_min_capacity >= 2
    error_message = "Production environment should have app_min_capacity >= 2 for high availability."
  }
}

# ── Stage safety guards ───────────────────────────────────────────────────────

check "stage_requires_waf" {
  assert {
    condition     = var.environment != "stage" || var.enable_waf
    error_message = "Stage environment should have enable_waf = true to mirror production behaviour."
  }
}

# ── VPC CIDR format ───────────────────────────────────────────────────────────

check "vpc_cidr_format" {
  assert {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr '${var.vpc_cidr}' is not a valid CIDR block."
  }
}

# ── Availability zones minimum ────────────────────────────────────────────────

check "minimum_two_availability_zones" {
  assert {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability_zones are required for high availability."
  }
}
