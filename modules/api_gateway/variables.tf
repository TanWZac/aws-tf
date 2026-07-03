variable "name_prefix" {
  description = "Name prefix used for API Gateway resources."
  type        = string
}

variable "backend_url" {
  description = "HTTP backend URL for the API Gateway proxy integration. Example: http://internal-or-public-alb.example.com"
  type        = string

  validation {
    condition     = can(regex("^https?://", var.backend_url))
    error_message = "backend_url must start with http:// or https://."
  }
}

variable "stage_name" {
  description = "API Gateway stage name. Use $default for the default HTTP API stage."
  type        = string
  default     = "$default"
}

variable "allowed_origins" {
  description = "CORS allowed origins. Defaults to empty (no CORS headers sent). Set explicitly per environment."
  type        = list(string)
  default     = []
}

variable "allowed_methods" {
  description = "CORS allowed methods."
  type        = list(string)
  default     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
}

variable "allowed_headers" {
  description = "CORS allowed headers."
  type        = list(string)
  default     = ["content-type", "authorization", "x-requested-with"]
}

variable "access_log_retention_days" {
  description = "CloudWatch access log retention in days."
  type        = number
  default     = 30
}

variable "throttling_burst_limit" {
  description = "Default route throttling burst limit."
  type        = number
  default     = 100
}

variable "throttling_rate_limit" {
  description = "Default route throttling rate limit per second."
  type        = number
  default     = 50
}

variable "auto_deploy" {
  description = "Whether the stage auto-deploys on configuration changes. Disable in prod for controlled rollouts."
  type        = bool
  default     = true
}

variable "enable_jwt_authorizer" {
  description = "Whether to attach a JWT authorizer to all routes."
  type        = bool
  default     = false
}

variable "jwt_issuer" {
  description = "JWT issuer URL (e.g. https://cognito-idp.<region>.amazonaws.com/<user_pool_id>). Required when enable_jwt_authorizer is true."
  type        = string
  default     = null
}

variable "jwt_audiences" {
  description = "List of JWT audiences (app client IDs). Required when enable_jwt_authorizer is true."
  type        = list(string)
  default     = []
}

variable "custom_domain_name" {
  description = "Optional custom domain name for API Gateway."
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the optional custom domain."
  type        = string
  default     = null
}
