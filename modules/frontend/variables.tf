variable "name_prefix" {
  description = "Common name prefix for all resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | stage | prod). Used in SSM parameter paths."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = US/Europe only (cheapest). PriceClass_All = global."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "custom_domain_name" {
  description = "Optional custom domain for the CloudFront distribution (e.g. app.example.com). Requires certificate_arn."
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the custom domain. Must be in us-east-1."
  type        = string
  default     = null

  validation {
    condition     = var.custom_domain_name == null || (var.certificate_arn != null && can(regex("^arn:aws:acm:us-east-1:", var.certificate_arn)))
    error_message = "certificate_arn must be a valid ACM ARN in us-east-1 when custom_domain_name is set."
  }
}
