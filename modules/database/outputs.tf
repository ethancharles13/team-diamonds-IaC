output "dynamodb_table_name" {
  description = "The name of the DynamoDB tokens table"
  value       = aws_dynamodb_table.tokens_table.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB tokens table"
  value       = aws_dynamodb_table.tokens_table.arn
}