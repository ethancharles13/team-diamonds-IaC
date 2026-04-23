output "oauth_lambda_invoke_arn" {
  description = "The invoke ARN for the OAuth Lambda"
  value       = aws_lambda_function.oauth_lambda.invoke_arn
}

output "action_lambda_invoke_arn" {
  description = "The invoke ARN for the Action Lambda"
  value       = aws_lambda_function.action_lambda.invoke_arn
}

output "oauth_lambda_function_name" {
  description = "The name of the OAuth Lambda"
  value       = aws_lambda_function.oauth_lambda.function_name
}

output "action_lambda_function_name" {
  description = "The name of the Action Lambda"
  value       = aws_lambda_function.action_lambda.function_name
}