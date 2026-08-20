variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "Local AWS CLI profile to use (leave null in CI)."
  type        = string
  default     = null
}
