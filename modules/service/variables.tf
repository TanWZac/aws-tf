variable "name_prefix" {
  description = "Common name prefix for resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where service resources are deployed."
  type        = string
}

variable "existing_ecs_cluster_id" {
  description = "ID of an existing ECS cluster to deploy into. When set (together with existing_ecs_cluster_name), the module skips creating its own cluster — used to co-locate a second service in an already-running cluster."
  type        = string
  default     = null
}

variable "existing_ecs_cluster_name" {
  description = "Name of an existing ECS cluster to deploy into. Must be set together with existing_ecs_cluster_id."
  type        = string
  default     = null

  validation {
    condition     = (var.existing_ecs_cluster_id == null) == (var.existing_ecs_cluster_name == null)
    error_message = "existing_ecs_cluster_id and existing_ecs_cluster_name must both be set, or both left null."
  }
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

variable "alb_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB on HTTP/HTTPS. Defaults to open; restrict for internal-only services."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecs_service_name" {
  description = "Override for the ECS service's name. Defaults to \"$${name_prefix}-app-svc\" when null."
  type        = string
  default     = null
}

variable "task_family" {
  description = "Override for the ECS task definition's family. Defaults to \"$${name_prefix}-app\" when null."
  type        = string
  default     = null
}

variable "container_name" {
  description = "Override for the app container's name. Defaults to \"app\" when null."
  type        = string
  default     = null
}

variable "efs_volume_name" {
  description = "Override for the EFS volume's name (used in both the task definition's volume block and its mountPoints entry). Defaults to \"efs-data\" when null."
  type        = string
  default     = null
}

variable "alb_sg_description" {
  description = "Override for the ALB security group's description. Defaults to \"ALB ingress security group.\" when null — changing this after creation forces replacement, so only override at creation time or via import to match a pre-existing group."
  type        = string
  default     = null
}

variable "service_sg_description" {
  description = "Override for the ECS service security group's description. Defaults to \"ECS service task security group.\" when null — same replacement caveat as alb_sg_description."
  type        = string
  default     = null
}

variable "service_sg_name" {
  description = "Override for the ECS service security group's name. Defaults to \"$${name_prefix}-service-sg\" when null."
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "Override for the CloudWatch log group name. Defaults to \"/$${name_prefix}/service\" when null."
  type        = string
  default     = null
}

variable "awslogs_stream_prefix" {
  description = "Override for the container's awslogs-stream-prefix. Defaults to \"app\" when null."
  type        = string
  default     = null
}

variable "container_command" {
  description = "Override for the container's command. Defaults to omitting the command key (uses the image's default ENTRYPOINT/CMD) when null."
  type        = list(string)
  default     = null
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

variable "omit_readonly_root_filesystem" {
  description = "When true, omit the readonlyRootFilesystem key from the container definition entirely instead of emitting container_readonly_root_filesystem's value. Use when adopting a pre-existing task definition that never set this key."
  type        = bool
  default     = false
}

variable "omit_container_secrets" {
  description = "When true, omit the secrets key from the container definition entirely instead of emitting container_secrets's value. Use when adopting a pre-existing task definition that never set this key."
  type        = bool
  default     = false
}

variable "enable_efs_volume" {
  description = "Whether to mount an EFS access point into the app container."
  type        = bool
  default     = false
}

variable "efs_file_system_id" {
  description = "EFS file system ID to mount. Required when enable_efs_volume is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_efs_volume || var.efs_file_system_id != null
    error_message = "efs_file_system_id must be set when enable_efs_volume is true."
  }
}

variable "efs_access_point_id" {
  description = "EFS access point ID to mount via IAM authorization. Required when enable_efs_volume is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_efs_volume || var.efs_access_point_id != null
    error_message = "efs_access_point_id must be set when enable_efs_volume is true."
  }
}

variable "efs_container_mount_path" {
  description = "Path inside the container where the EFS access point is mounted."
  type        = string
  default     = "/mnt/efs"
}

variable "efs_read_only" {
  description = "Whether the container's EFS mount point is read-only."
  type        = bool
  default     = true
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

variable "existing_task_execution_role_arn" {
  description = "ARN of an existing ECS task execution role to reuse instead of creating one. When set, the module creates no execution role."
  type        = string
  default     = null
}
