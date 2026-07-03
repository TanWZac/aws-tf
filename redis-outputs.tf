output "redis_primary_endpoint" {
  description = "Primary Redis endpoint address."
  value       = var.enable_redis ? module.redis[0].primary_endpoint_address : null
}

output "redis_reader_endpoint" {
  description = "Reader Redis endpoint address."
  value       = var.enable_redis ? module.redis[0].reader_endpoint_address : null
}

output "redis_port" {
  description = "Redis port."
  value       = var.enable_redis ? module.redis[0].port : null
}

output "redis_security_group_id" {
  description = "Redis security group ID."
  value       = var.enable_redis ? module.redis[0].security_group_id : null
}
