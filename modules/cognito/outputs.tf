output "user_pool_id" {
  description = "Cognito User Pool ID."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN."
  value       = aws_cognito_user_pool.this.arn
}

output "client_id" {
  description = "Cognito App Client ID."
  value       = aws_cognito_user_pool_client.this.id
}

output "issuer_url" {
  description = "JWT issuer URL for API Gateway JWT authorizer."
  value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}

output "jwks_url" {
  description = "JWKS URL for JWT validation."
  value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}/.well-known/jwks.json"
}

output "hosted_ui_domain" {
  description = "Cognito hosted UI domain (null if auth_domain_prefix was not set)."
  value       = var.auth_domain_prefix != null ? "https://${var.auth_domain_prefix}.auth.${data.aws_region.current.name}.amazoncognito.com" : null
}
