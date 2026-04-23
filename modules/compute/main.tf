# Note: Infrastructure CI/CD pipeline and application CI/CD pipeline are completley separate.
# The application CI/CD pipeline is responsible for injecting the needed dependencies and source code 
# into the lambda functions. If the lambdas are torn down and redeployed, the application CI/CD pipeline
# needs to be manually triggered to ensure source code and dependencies are deployed to the lambdas.

# IAM Role & Policy: OAuth Lambda
resource "aws_iam_role" "oauth_lambda_role" {
  name = "oauth-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "oauth_lambda_policy" {
  name = "oauth-lambda-policy"
  role = aws_iam_role.oauth_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# Lambda Function: OAuth Lambda

resource "aws_lambda_function" "oauth_lambda" {
  function_name = "oauth-lambda"
  role          = aws_iam_role.oauth_lambda_role.arn
  handler       = "main.handler"
  runtime       = "python3.12"
  filename      = "${path.module}/dummy_payload.zip"

  environment {
    variables = {
      DYNAMODB_TABLE_ARN = var.dynamodb_table_arn
    }
  }

  lifecycle {
    ignore_changes = [
      layers,
      source_code_hash,
      filename
    ]
  }
}

# IAM Role & Policy: Action Lambda

resource "aws_iam_role" "action_lambda_role" {
  name = "action-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "action_lambda_policy" {
  name = "action-lambda-policy"
  role = aws_iam_role.action_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# Lambda Function: Action Lambda

resource "aws_lambda_function" "action_lambda" {
  function_name = "action-lambda"
  role          = aws_iam_role.action_lambda_role.arn
  handler       = "main.handler" # ToDO: Update to match your python entrypoint
  runtime       = "python3.12"
  filename      = "${path.module}/dummy_payload.zip"

  environment {
    variables = {
      DYNAMODB_TABLE_ARN = var.dynamodb_table_arn
    }
  }

  lifecycle {
    ignore_changes = [
      layers,
      source_code_hash,
      filename
    ]
  }
}