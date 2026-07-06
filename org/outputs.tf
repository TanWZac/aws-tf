output "organization_id" {
  description = "The AWS Organization ID."
  value       = aws_organizations_organization.this.id
}

output "prod_primary_account_id" {
  description = "Account ID for prod-primary (accounts.tf account_a)."
  value       = aws_organizations_account.prod_primary.id
}

output "prod_secondary_account_id" {
  description = "Account ID for prod-secondary (accounts.tf account_b), if enabled."
  value       = var.enable_prod_secondary ? aws_organizations_account.prod_secondary[0].id : null
}

output "dev_account_id" {
  description = "Account ID for dev (accounts.tf account_c)."
  value       = aws_organizations_account.dev.id
}

output "stage_account_id" {
  description = "Account ID for stage (accounts.tf account_stage)."
  value       = aws_organizations_account.stage.id
}

output "security_tooling_account_id" {
  description = "Account ID for security-tooling (not referenced by root accounts.tf)."
  value       = aws_organizations_account.security_tooling.id
}

output "log_archive_account_id" {
  description = "Account ID for log-archive (not referenced by root accounts.tf)."
  value       = aws_organizations_account.log_archive.id
}

# Rendered root accounts.tf content. Consumed by `make org-sync-accounts`,
# which runs: terraform -chdir=org output -raw accounts_tf_content > accounts.tf
output "accounts_tf_content" {
  description = "Full contents of a ready-to-write root accounts.tf, with real account IDs filled in."
  value = templatefile("${path.module}/templates/accounts.tf.tpl", {
    aws_region       = var.aws_region
    account_a_id     = aws_organizations_account.prod_primary.id
    account_b_id     = var.enable_prod_secondary ? aws_organizations_account.prod_secondary[0].id : ""
    account_c_id     = aws_organizations_account.dev.id
    account_stage_id = aws_organizations_account.stage.id
  })
}
