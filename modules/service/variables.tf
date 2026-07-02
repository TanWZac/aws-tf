variable "name_prefix" {
  description = "Common name prefix for resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where service resources are deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB placement."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "container_image" {
  description = "Container image URI for app tasks."
  type        = string
}

variable "container_port" {
  description = "Application container port."
  type        = number
}

variable "task_cpu" {
  description = "CPU units per task."
  type        = number
}

variable "task_memory" {
  description = "Memory MiB per task."
  type        = number
}

variable "desired_count" {
  description = "Desired running task count."
  type        = number
}

variable "min_capacity" {
  description = "Minimum autoscaling task count."
  type        = number
}

variable "max_capacity" {
  description = "Maximum autoscaling task count."
  type        = number
}

variable "health_check_path" {
  description = "Health check path for ALB target group."
  type        = string
}

variable "enable_https" {
  description = "Whether to enable HTTPS listener on the ALB."
  type        = bool
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string

  validation {
    condition     = !var.enable_https || can(regex("^arn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate/.+", var.certificate_arn))
    error_message = "certificate_arn must be a valid ACM certificate ARN when enable_https is true."
  }
}

variable "ssl_policy" {
  description = "TLS policy for HTTPS listener."
  type        = string
}

variable "enable_waf" {
  description = "Whether to attach WAF web ACL to the ALB."
  type        = bool
}

variable "waf_rate_limit" {
  description = "Rate limit per source IP in 5-minute window."
  type        = number
}

variable "enable_deletion_protection" {
  description = "Whether to enable ALB deletion protection."
  type        = bool
}

variable "enable_alb_access_logs" {
  description = "Whether to enable ALB access logging to S3."
  type        = bool
}

variable "enable_waf_logging" {
  description = "Whether to enable WAF logging through Firehose to S3."
  type        = bool
}

variable "create_edge_logs_bucket" {
  description = "Whether to create an S3 bucket for ALB/WAF logs."
  type        = bool
}

variable "edge_logs_bucket_name" {
  description = "Optional existing S3 bucket name for ALB/WAF logs. If null and create_edge_logs_bucket is true, bucket is created."
  type        = string
}

variable "edge_logs_prefix" {
  description = "S3 prefix used for ALB/WAF log delivery."
  type        = string
}

variable "enable_deployment_circuit_breaker" {
  description = "Whether to enable ECS deployment circuit breaker."
  type        = bool
}

variable "deployment_rollback_on_failure" {
  description = "Whether ECS should roll back failed deployments when circuit breaker is enabled."
  type        = bool
}

variable "enable_request_count_autoscaling" {
  description = "Whether to autoscale ECS service based on ALB request count per target."
  type        = bool
}

variable "request_count_target" {
  description = "Target ALB requests per target for autoscaling policy."
  type        = number
}

variable "request_scale_in_cooldown" {
  description = "Scale-in cooldown (seconds) for request-count autoscaling policy."
  type        = number
}

variable "request_scale_out_cooldown" {
  description = "Scale-out cooldown (seconds) for request-count autoscaling policy."
  type        = number
}
