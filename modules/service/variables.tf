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
