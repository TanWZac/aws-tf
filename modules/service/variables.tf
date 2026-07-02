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
