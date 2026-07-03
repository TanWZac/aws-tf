variable "name_prefix" {
  description = "Common name prefix for Cognito resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Used in SSM parameter paths."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "callback_urls" {
  description = "Allowed OAuth callback URLs for the app client (e.g. https://app.example.com/callback)."
  type        = list(string)

  validation {
    condition     = length(var.callback_urls) > 0
    error_message = "At least one callback URL is required."
  }
}

variable "logout_urls" {
  description = "Allowed sign-out URLs for the app client."
  type        = list(string)

  validation {
    condition     = length(var.logout_urls) > 0
    error_message = "At least one logout URL is required."
  }
}

variable "auth_domain_prefix" {
  description = "Cognito hosted UI domain prefix (e.g. 'my-app-dev'). Creates <prefix>.auth.<region>.amazoncognito.com."
  type        = string
  default     = null
}

variable "advanced_security_mode" {
  description = "Cognito advanced security mode. AUDIT logs threats; ENFORCED blocks them. Use ENFORCED for production."
  type        = string
  default     = "ENFORCED"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "advanced_security_mode must be OFF, AUDIT, or ENFORCED."
  }
}
