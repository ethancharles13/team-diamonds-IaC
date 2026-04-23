variable "aws_region" {
  default = "us-east-2"
}

variable "cognito_user_pool_arn" {
  description = "The ARN of the AWS Cognito User Pool"
  type        = string
}

variable "oauth_lambda_invoke_arn" {
  description = "The Invoke ARN of the OAuth Lambda function"
  type        = string
}

variable "action_lambda_invoke_arn" {
  description = "The Invoke ARN of the Jira/Slack Action Lambda function"
  type        = string
}

variable "oauth_lambda_function_name" {
  description = "The name of the OAuth Lambda function"
  type        = string
}

variable "action_lambda_function_name" {
  description = "The name of the Jira/Slack Action Lambda function"
  type        = string
}