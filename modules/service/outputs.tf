output "alb_dns_name" {
  description = "Public DNS name for the app load balancer."
  value       = aws_lb.this.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "service_security_group_id" {
  description = "Security group ID attached to ECS tasks."
  value       = aws_security_group.service.id
}

output "alerts_sns_topic_arn" {
  description = "ARN of the SNS topic that receives CloudWatch alarm notifications."
  value       = var.enable_alarms ? aws_sns_topic.alerts[0].arn : null
}
