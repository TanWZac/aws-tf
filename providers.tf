provider "aws" {
  region = var.aws_region
  profile = var.aws_profile

  allowed_account_ids = local.env_account_ids

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
