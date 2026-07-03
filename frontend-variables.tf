# ── Frontend (S3 + CloudFront) ────────────────────────────────────────────────

variable "enable_frontend" {
  description = "Whether to provision the S3 + CloudFront frontend hosting stack."
  type        = bool
  default     = false
}

variable "frontend_price_class" {
  description = "CloudFront price class for the frontend distribution."
  type        = string
  default     = "PriceClass_100"
}

variable "frontend_custom_domain_name" {
  description = "Optional custom domain for the CloudFront distribution."
  type        = string
  default     = null
}

variable "frontend_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1) for the optional custom domain."
  type        = string
  default     = null
}
