# ── Cognito ───────────────────────────────────────────────────────────────────

variable "enable_cognito" {
  description = "Whether to provision a Cognito User Pool and app client."
  type        = bool
  default     = false
}

variable "cognito_callback_urls" {
  description = "Allowed OAuth callback URLs (e.g. https://app.example.com/callback)."
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "cognito_logout_urls" {
  description = "Allowed sign-out redirect URLs."
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "cognito_auth_domain_prefix" {
  description = "Cognito hosted UI subdomain prefix. Creates <prefix>.auth.<region>.amazoncognito.com."
  type        = string
  default     = null
}
