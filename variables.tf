variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional local AWS profile name. Keep null in CI or when using role-based auth."
  type        = string
  default     = null
}

variable "allowed_account_ids" {
  description = "Optional guardrail: allowed AWS account IDs for deployment."
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project identifier used in resource names."
  type        = string
  default     = "platform-ai"
}

variable "environment" {
  description = "Environment name, for example dev, test, or prod."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the platform VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used for subnet placement."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "nat_gateway_mode" {
  description = "NAT mode for private subnets: none, single, or per_az."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be one of: none, single, per_az."
  }
}

variable "enable_vpc_endpoints" {
  description = "Whether to provision VPC endpoints for core AWS services."
  type        = bool
  default     = true
}

variable "create_sagemaker_notebook" {
  description = "Whether to create a SageMaker notebook instance."
  type        = bool
  default     = true
}

variable "sagemaker_instance_type" {
  description = "Instance type for the SageMaker notebook instance."
  type        = string
  default     = "ml.t3.medium"
}

variable "enable_app_service" {
  description = "Whether to deploy the autoscaling ECS service behind ALB."
  type        = bool
  default     = true
}

variable "app_container_image" {
  description = "Container image URI for the app service."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "app_container_port" {
  description = "Container port exposed by the app service."
  type        = number
  default     = 80
}

variable "app_task_cpu" {
  description = "CPU units for each ECS task."
  type        = number
  default     = 512
}

variable "app_task_memory" {
  description = "Memory in MiB for each ECS task."
  type        = number
  default     = 1024
}

variable "app_desired_count" {
  description = "Desired number of ECS tasks."
  type        = number
  default     = 2
}

variable "app_min_capacity" {
  description = "Minimum ECS service task count for autoscaling."
  type        = number
  default     = 2
}

variable "app_max_capacity" {
  description = "Maximum ECS service task count for autoscaling."
  type        = number
  default     = 10
}

variable "app_health_check_path" {
  description = "Health check path for the load balancer target group."
  type        = string
  default     = "/"
}

variable "enable_alb_https" {
  description = "Whether to expose the app service through HTTPS listener on ALB."
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN used by ALB HTTPS listener."
  type        = string
  default     = null
}

variable "alb_ssl_policy" {
  description = "SSL policy for ALB HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_waf" {
  description = "Whether to attach AWS WAF web ACL to the ALB."
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Rate limit (requests per 5 minutes per IP) for WAF rate-based rule."
  type        = number
  default     = 2000
}

variable "enable_alb_deletion_protection" {
  description = "Enable deletion protection for ALB. Should be true for stage/prod."
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logs to S3."
  type        = bool
  default     = true
}

variable "enable_waf_logging" {
  description = "Enable WAF logs through Firehose to S3."
  type        = bool
  default     = true
}

variable "create_edge_logs_bucket" {
  description = "Create a dedicated S3 bucket for ALB and WAF logs."
  type        = bool
  default     = true
}

variable "edge_logs_bucket_name" {
  description = "Existing bucket name for edge logs. If null and create_edge_logs_bucket is true, a bucket is created."
  type        = string
  default     = null
}

variable "edge_logs_prefix" {
  description = "Prefix for ALB/WAF logs inside edge logs bucket."
  type        = string
  default     = "edge"
}

variable "edge_logs_retention_days" {
  description = "Lifecycle expiration days for edge logs objects."
  type        = number
  default     = 90
}

variable "enable_edge_logs_kms_encryption" {
  description = "Enable KMS encryption for edge log bucket and Firehose path."
  type        = bool
  default     = false
}

variable "create_edge_logs_kms_key" {
  description = "Create a dedicated KMS key for edge logs when KMS encryption is enabled."
  type        = bool
  default     = true
}

variable "edge_logs_kms_key_arn" {
  description = "Existing KMS key ARN for edge logs encryption when create_edge_logs_kms_key is false."
  type        = string
  default     = null
}

variable "enable_deployment_circuit_breaker" {
  description = "Enable ECS deployment circuit breaker."
  type        = bool
  default     = true
}

variable "deployment_rollback_on_failure" {
  description = "When deployment circuit breaker is enabled, roll back failed deployments."
  type        = bool
  default     = true
}

variable "enable_request_count_autoscaling" {
  description = "Enable ALB request-count-based autoscaling for ECS service."
  type        = bool
  default     = true
}

variable "request_count_target" {
  description = "Target ALB requests per target for request-count autoscaling policy."
  type        = number
  default     = 800
}

variable "request_scale_in_cooldown" {
  description = "Scale-in cooldown in seconds for request-count autoscaling policy."
  type        = number
  default     = 180
}

variable "request_scale_out_cooldown" {
  description = "Scale-out cooldown in seconds for request-count autoscaling policy."
  type        = number
  default     = 60
}

variable "additional_tags" {
  description = "Additional tags applied to all resources through AWS provider default tags."
  type        = map(string)
  default     = {}
}
