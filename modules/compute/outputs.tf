output "action_lambda_invoke_arn" {
  description = "The invoke ARN for the Action Lambda"
  value       = aws_lambda_function.action_lambda.invoke_arn
}

output "action_lambda_function_name" {
  description = "The name of the Action Lambda"
  value       = aws_lambda_function.action_lambda.function_name
}