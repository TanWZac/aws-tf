variable "name_prefix" {
  description = "Common name prefix for resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where AI resources are deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for AI workloads."
  type        = list(string)
}

variable "create_sagemaker_notebook" {
  description = "Whether to create a SageMaker notebook instance."
  type        = bool
}

variable "sagemaker_instance_type" {
  description = "SageMaker notebook instance type."
  type        = string
}
