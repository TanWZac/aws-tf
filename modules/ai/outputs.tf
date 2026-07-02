output "dataset_bucket_name" {
  description = "AI dataset bucket name."
  value       = aws_s3_bucket.dataset.bucket
}

output "sagemaker_execution_role_arn" {
  description = "IAM role ARN for SageMaker execution."
  value       = aws_iam_role.sagemaker_execution.arn
}

output "sagemaker_notebook_name" {
  description = "SageMaker notebook name if created."
  value       = var.create_sagemaker_notebook ? aws_sagemaker_notebook_instance.this[0].name : null
}

output "ecr_repository_url" {
  description = "ECR repository URL for model containers."
  value       = aws_ecr_repository.models.repository_url
}
