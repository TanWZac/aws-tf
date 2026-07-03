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

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "task_cpu" {
  description = "CPU units per task. Must be a valid Fargate CPU value."
  type        = number

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.task_cpu)
    error_message = "task_cpu must be a valid Fargate CPU value: 256, 512, 1024, 2048, 4096, 8192, or 16384."
  }
}

variable "task_memory" {
  description = "Memory MiB per task. Must be compatible with the chosen task_cpu."
  type        = number

  validation {
    condition     = var.task_memory >= 512 && var.task_memory % 512 == 0
    error_message = "task_memory must be a multiple of 512 and at least 512 MiB."
  }
}

variable "desired_count" {
  description = "Desired running task count."
  type        = number

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be 0 or greater."
  }
}

variable "min_capacity" {
  description = "Minimum autoscaling task count."
  type        = number

  validation {
    condition     = var.min_capacity >= 0
    error_message = "min_capacity must be 0 or greater."
  }
}

variable "max_capacity" {
  description = "Maximum autoscaling task count."
  type        = number

  validation {
    condition     = var.max_capacity >= 1
    error_message = "max_capacity must be at least 1."
  }
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

  validation {
    condition     = (var.enable_alb_access_logs || (var.enable_waf && var.enable_waf_logging)) ? (var.create_edge_logs_bucket || var.edge_logs_bucket_name != null) : true
    error_message = "edge_logs_bucket_name must be provided when edge logging is enabled and create_edge_logs_bucket is false."
  }
}

variable "edge_logs_prefix" {
  description = "S3 prefix used for ALB/WAF log delivery."
  type        = string
}

variable "edge_logs_retention_days" {
  description = "Lifecycle expiration in days for edge logs objects."
  type        = number
}

variable "enable_edge_logs_kms_encryption" {
  description = "Whether to use KMS encryption for edge log bucket and Firehose delivery."
  type        = bool
}

variable "create_edge_logs_kms_key" {
  description = "Whether to create a KMS key for edge logs when KMS encryption is enabled."
  type        = bool
}

variable "edge_logs_kms_key_arn" {
  description = "Existing KMS key ARN for edge logs encryption. Used when create_edge_logs_kms_key is false."
  type        = string

  validation {
    condition     = !var.enable_edge_logs_kms_encryption || var.create_edge_logs_kms_key || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/.+", var.edge_logs_kms_key_arn))
    error_message = "edge_logs_kms_key_arn must be a valid KMS key ARN when KMS encryption is enabled and key creation is disabled."
  }
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

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore ALB health check failures after a task starts. Prevents rapid cycling during slow startup."
  type        = number
  default     = 60
}

variable "task_role_arn" {
  description = "IAM role ARN for the ECS task itself (application permissions, e.g. Secrets Manager, S3). Distinct from the execution role."
  type        = string
  default     = null
}

variable "container_environment" {
  description = "List of plain-text environment variables to inject into the container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "container_secrets" {
  description = "List of secrets from SSM Parameter Store or Secrets Manager to inject as environment variables. valueFrom must be an SSM or Secrets Manager ARN."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "container_readonly_root_filesystem" {
  description = "Mount the container root filesystem as read-only. Recommended true for production."
  type        = bool
  default     = false
}

# ── Alarms ────────────────────────────────────────────────────────────────────

variable "enable_alarms" {
  description = "Whether to create CloudWatch metric alarms."
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address to notify when an alarm fires. Leave null to skip email subscription (wire up SNS manually)."
  type        = string
  default     = null
}

variable "alarm_actions" {
  description = "Additional SNS topic ARNs to notify. The module always creates its own SNS topic; use this to add extra targets."
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "Additional SNS topic ARNs to notify on alarm recovery."
  type        = list(string)
  default     = []
}

variable "cpu_alarm_threshold" {
  description = "ECS average CPU utilisation percentage that triggers an alarm."
  type        = number
  default     = 85
}

variable "memory_alarm_threshold" {
  description = "ECS average memory utilisation percentage that triggers an alarm."
  type        = number
  default     = 85
}

variable "http_5xx_alarm_threshold" {
  description = "Number of ALB 5xx responses per minute that triggers an alarm."
  type        = number
  default     = 10
}

variable "environment" {
  description = "Deployment environment (dev | stage | prod). Used in SSM parameter paths."
  type        = string
  default     = null
}
