variable "aws_region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional local AWS profile."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project identifier used in bucket and table names."
  type        = string
  default     = "platform-ai"
}
