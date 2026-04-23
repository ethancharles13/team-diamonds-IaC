output "api_base_url" {
  description = "The base URL for your API Gateway stage"
  value       = aws_api_gateway_stage.prod_stage.invoke_url
}

output "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway to pass to the Lambdas."
  value       = aws_api_gateway_rest_api.team_diamonds_api.execution_arn
}