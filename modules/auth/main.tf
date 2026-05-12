resource "aws_cognito_user_pool" "main_pool" {
  name = "team-diamonds-user-pool"

  # Allow users to log in with their email address
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
  }
}

resource "aws_cognito_user_pool_client" "web_client" {
  name         = "team-diamonds-web-client"
  user_pool_id = aws_cognito_user_pool.main_pool.id

  # Best practice for modern web apps using Cognito
  explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls        = ["https://d4m8l7smfuvyo.cloudfront.net/callback"]
  logout_urls          = ["https://d4m8l7smfuvyo.cloudfront.net/"]
  default_redirect_uri = "https://d4m8l7smfuvyo.cloudfront.net/callback"
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "team-diamonds"
  user_pool_id = aws_cognito_user_pool.main_pool.id
}

resource "aws_ssm_parameter" "cognito_authority_url" {
  name  = "/frontend/cognito/authority_url"
  type  = "String"
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth-us-east-2.amazoncognito.com"
}

# (Keep the client ID parameter if your frontend still needs it)
resource "aws_ssm_parameter" "cognito_client_id" {
  name  = "/frontend/cognito/client_id"
  type  = "String"
  value = aws_cognito_user_pool_client.web_client.id
}