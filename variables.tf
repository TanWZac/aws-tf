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

variable "additional_tags" {
  description = "Additional tags applied to all resources through AWS provider default tags."
  type        = map(string)
  default     = {}
}
