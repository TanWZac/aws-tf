variable "aws_region" {
  description = "Region for the management-account provider (Organizations/CloudTrail resources are mostly global, but the provider still needs one)."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Named AWS CLI profile with admin access to the management (payer) account. Keep null in CI or when using role-based auth."
  type        = string
  default     = null
}

variable "management_account_id" {
  description = "12-digit AWS Organizations management account ID. Used as a provider guardrail."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
}

variable "project_name" {
  description = "Project identifier used in account names and resource naming. Should match root variable.project_name."
  type        = string
  default     = "platform-ai"
}

# ── Account emails ──────────────────────────────────────────────────────────────
# AWS requires each account ever created to have a globally unique email
# address. "+" aliases on a domain you control work fine, e.g.
# aws+prod@yourcompany.com, aws+dev@yourcompany.com.

variable "log_archive_account_email" {
  description = "Unique email for the log-archive account (CloudTrail aggregation)."
  type        = string
}

variable "security_account_email" {
  description = "Unique email for the security-tooling account."
  type        = string
}

variable "prod_primary_account_email" {
  description = "Unique email for the primary production account (maps to accounts.tf account_a)."
  type        = string
}

variable "enable_prod_secondary" {
  description = "Whether to create a secondary/DR production account (maps to accounts.tf account_b)."
  type        = bool
  default     = false
}

variable "prod_secondary_account_email" {
  description = "Unique email for the secondary production account. Required when enable_prod_secondary is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_prod_secondary || var.prod_secondary_account_email != null
    error_message = "prod_secondary_account_email must be set when enable_prod_secondary is true."
  }
}

variable "dev_account_email" {
  description = "Unique email for the dev account (maps to accounts.tf account_c)."
  type        = string
}

variable "stage_account_email" {
  description = "Unique email for the stage account (maps to accounts.tf account_stage)."
  type        = string
}

# ── Guardrails ──────────────────────────────────────────────────────────────────

variable "approved_regions" {
  description = "Regions workload accounts are allowed to operate in. Keep in sync with root variable.availability_zones region."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

# ── Budget ──────────────────────────────────────────────────────────────────────

variable "monthly_budget_usd" {
  description = "Monthly total spend threshold across the org, in USD."
  type        = string
  default     = "500"
}

variable "billing_alert_email" {
  description = "Where budget threshold alerts (80% actual, 100% forecasted) are sent."
  type        = string
}
