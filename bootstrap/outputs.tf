output "state_bucket" {
  description = "Legacy/self-managed backend only: S3 bucket name for Terraform state."
  value       = aws_s3_bucket.state.bucket
}

output "lock_table" {
  description = "Legacy/self-managed backend only: DynamoDB table name for state locking."
  value       = aws_dynamodb_table.lock.name
}

output "aws_region" {
  description = "Region where resources were created."
  value       = var.aws_region
}
