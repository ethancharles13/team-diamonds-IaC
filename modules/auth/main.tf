resource "aws_cognito_user_pool" "main_pool" {
  name = "team-diamonds-user-pool"

  # Allow users to log in with their email address
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "web_client" {
  name         = "team-diamonds-web-client"
  user_pool_id = aws_cognito_user_pool.main_pool.id

  # Best practice for modern web apps using Cognito
  explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}