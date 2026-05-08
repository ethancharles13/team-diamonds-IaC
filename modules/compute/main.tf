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

# S3 bucket for deploying frontend
resource "aws_s3_bucket" "team_diamonds_s3" {
  bucket = "team-diamonds-s3"
}

resource "aws_s3_bucket_website_configuration" "team_diamonds_frontend" {
  bucket = aws_s3_bucket.team_diamonds_s3.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}


resource "aws_s3_bucket_public_access_block" "allow_public_access" {
  bucket = aws_s3_bucket.team_diamonds_s3.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.team_diamonds_s3.id

  depends_on = [aws_s3_bucket_public_access_block.allow_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.team_diamonds_s3.arn}/*"
      }
    ]
  })
}

#SSM parameters help separate IaC CI/CD pipeline from Application CI/CD pipeline
resource "aws_ssm_parameter" "oauth_lambda_name" {
  name  = "oauth-lambda"
  type  = "String"
  value = aws_lambda_function.oauth_lambda.function_name
}

resource "aws_ssm_parameter" "action_lambda_name" {
  name  = "action-lambda"
  type  = "String"
  value = aws_lambda_function.action_lambda.function_name
}

resource "aws_ssm_parameter" "front_end_bucket_name" {
  name  = "front-end-bucket"
  type  = "String"
  value = aws_s3_bucket.team_diamonds_s3.id
}