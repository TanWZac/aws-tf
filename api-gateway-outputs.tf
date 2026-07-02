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
