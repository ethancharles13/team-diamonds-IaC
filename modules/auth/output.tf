output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main_pool.id
}

output "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main_pool.arn
}

output "cognito_web_client_id" {
  value = aws_cognito_user_pool_client.web_client.id
}