variable "enable_api_gateway" {
  description = "Whether to provision API Gateway in front of the app service."
  type        = bool
  default     = false
}

variable "api_gateway_stage_name" {
  description = "API Gateway stage name."
  type        = string
  default     = "$default"
}

variable "api_gateway_allowed_origins" {
  description = "CORS allowed origins. Defaults to empty (no CORS headers sent). Set explicitly per environment."
  type        = list(string)
  default     = []
}

variable "api_gateway_allowed_methods" {
  description = "CORS allowed methods."
  type        = list(string)
  default     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
}

variable "api_gateway_allowed_headers" {
  description = "CORS allowed headers."
  type        = list(string)
  default     = ["content-type", "authorization", "x-requested-with"]
}

variable "api_gateway_access_log_retention_days" {
  description = "CloudWatch access log retention days."
  type        = number
  default     = 30
}

variable "api_gateway_throttling_burst_limit" {
  description = "Default throttling burst limit."
  type        = number
  default     = 100
}

variable "api_gateway_throttling_rate_limit" {
  description = "Default throttling rate limit per second."
  type        = number
  default     = 50
}

variable "api_gateway_custom_domain_name" {
  description = "Optional custom API Gateway domain name."
  type        = string
  default     = null
}

variable "api_gateway_certificate_arn" {
  description = "ACM certificate ARN for optional custom domain."
  type        = string
  default     = null
}

variable "api_gateway_auto_deploy" {
  description = "Whether API Gateway stage auto-deploys. Set to false in prod for controlled rollouts."
  type        = bool
  default     = true
}

variable "api_gateway_enable_jwt_authorizer" {
  description = "Whether to attach a JWT authorizer to all API Gateway routes."
  type        = bool
  default     = false
}

variable "api_gateway_jwt_issuer" {
  description = "JWT issuer URL. Required when api_gateway_enable_jwt_authorizer is true."
  type        = string
  default     = null
}

variable "api_gateway_jwt_audiences" {
  description = "JWT audience list (app client IDs). Required when api_gateway_enable_jwt_authorizer is true."
  type        = list(string)
  default     = []
}
