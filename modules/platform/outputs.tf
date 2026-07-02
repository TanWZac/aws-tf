output "vpc_id" {
  description = "ID of the platform VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "workloads_security_group_id" {
  description = "Shared security group for workloads."
  value       = aws_security_group.workloads.id
}

output "platform_bucket_name" {
  description = "Name of shared platform bucket."
  value       = aws_s3_bucket.platform.bucket
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID used by interface VPC endpoints."
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}
