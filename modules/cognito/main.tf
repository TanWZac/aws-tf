resource "aws_cognito_user_pool" "this" {
  name = "${var.name_prefix}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }

  tags = {
    Name = "${var.name_prefix}-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.name_prefix}-app-client"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false # SPA clients cannot keep a secret

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  access_token_validity  = 1    # hours
  id_token_validity      = 1    # hours
  refresh_token_validity = 30   # days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}

resource "aws_cognito_user_pool_domain" "this" {
  count        = var.auth_domain_prefix != null ? 1 : 0
  domain       = var.auth_domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

# ── SSM parameters (consumed by backend and API Gateway JWT authorizer) ───────

resource "aws_ssm_parameter" "user_pool_id" {
  name  = "/platform/${var.environment}/cognito-pool-id"
  type  = "String"
  value = aws_cognito_user_pool.this.id
}

resource "aws_ssm_parameter" "client_id" {
  name  = "/platform/${var.environment}/cognito-client-id"
  type  = "String"
  value = aws_cognito_user_pool_client.this.id
}

resource "aws_ssm_parameter" "jwks_url" {
  name  = "/platform/${var.environment}/cognito-jwks-url"
  type  = "String"
  value = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}/.well-known/jwks.json"
}

resource "aws_ssm_parameter" "issuer_url" {
  name  = "/platform/${var.environment}/cognito-issuer-url"
  type  = "String"
  value = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}

data "aws_region" "current" {}
