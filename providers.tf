provider "aws" {
  region = var.aws_region
  profile = var.aws_profile

  # Prefer the central accounts.tf registry; var.allowed_account_ids overrides when set explicitly.
  allowed_account_ids = length(var.allowed_account_ids) > 0 ? var.allowed_account_ids : local.env_account_ids

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "Terraform"
      },
      var.additional_tags
    )
  }
}
