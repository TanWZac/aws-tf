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

# ── API Gateway (optional) ────────────────────────────────────────────────────

output "api_gateway_endpoint" {
  description = "API Gateway base endpoint."
  value       = var.enable_api_gateway && var.enable_app_service ? module.api_gateway[0].api_endpoint : null
}

output "api_gateway_stage_invoke_url" {
  description = "API Gateway stage invoke URL."
  value       = var.enable_api_gateway && var.enable_app_service ? module.api_gateway[0].stage_invoke_url : null
}

output "api_gateway_access_log_group_name" {
  description = "API Gateway access log group name."
  value       = var.enable_api_gateway && var.enable_app_service ? module.api_gateway[0].access_log_group_name : null
}
