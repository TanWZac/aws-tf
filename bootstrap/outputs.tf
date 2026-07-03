output "state_bucket" {
  description = "S3 bucket name for Terraform remote state. Copy into environments/*/backend.hcl as: bucket = \"<value>\""
  value       = aws_s3_bucket.state.bucket
}

output "lock_table" {
  description = "DynamoDB table name for state locking. Copy into environments/*/backend.hcl as: dynamodb_table = \"<value>\""
  value       = aws_dynamodb_table.lock.name
}

output "aws_region" {
  description = "Region where resources were created."
  value       = var.aws_region
}
