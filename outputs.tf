output "platform_vpc_id" {
  description = "VPC ID created by the platform module."
  value       = module.platform.vpc_id
}

output "platform_private_subnets" {
  description = "Private subnet IDs used by workloads."
  value       = module.platform.private_subnet_ids
}

output "ai_dataset_bucket" {
  description = "S3 bucket for AI datasets and model artifacts."
  value       = module.ai.dataset_bucket_name
}

output "ai_ecr_repository_url" {
  description = "ECR repository URL for model images."
  value       = module.ai.ecr_repository_url
}

output "app_alb_dns_name" {
  description = "ALB DNS name for the autoscaling application service."
  value       = var.enable_app_service ? module.service[0].alb_dns_name : null
}

output "app_ecs_cluster_name" {
  description = "ECS cluster name hosting the app service."
  value       = var.enable_app_service ? module.service[0].ecs_cluster_name : null
}
