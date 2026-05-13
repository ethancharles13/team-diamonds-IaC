# API Gateway & Authorizer

resource "aws_api_gateway_rest_api" "team_diamonds_api" {
  name        = "team-diamonds-api"
  description = "Monolithic API Gateway for team-diamonds project."
}

resource "aws_api_gateway_authorizer" "cognito_auth" {
  name          = "cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.team_diamonds_api.id
  provider_arns = [var.cognito_user_pool_arn]
}


# /ACTIONS ENDPOINT

resource "aws_api_gateway_resource" "actions_resource" {
  rest_api_id = aws_api_gateway_rest_api.team_diamonds_api.id
  parent_id   = aws_api_gateway_rest_api.team_diamonds_api.root_resource_id
  path_part   = "actions"
}

# ANY Method acts as Proxy to Lambda
resource "aws_api_gateway_method" "actions_method" {
  rest_api_id   = aws_api_gateway_rest_api.team_diamonds_api.id
  resource_id   = aws_api_gateway_resource.actions_resource.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_integration" "actions_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.team_diamonds_api.id
  resource_id             = aws_api_gateway_resource.actions_resource.id
  http_method             = aws_api_gateway_method.actions_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.action_lambda_invoke_arn
}

# OPTIONS Method for CORS Preflight
resource "aws_api_gateway_method" "actions_options" {
  rest_api_id   = aws_api_gateway_rest_api.team_diamonds_api.id
  resource_id   = aws_api_gateway_resource.actions_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "actions_options_mock" {
  rest_api_id = aws_api_gateway_rest_api.team_diamonds_api.id
  resource_id = aws_api_gateway_resource.actions_resource.id
  http_method = aws_api_gateway_method.actions_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "actions_options_200" {
  rest_api_id = aws_api_gateway_rest_api.team_diamonds_api.id
  resource_id = aws_api_gateway_resource.actions_resource.id
  http_method = aws_api_gateway_method.actions_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "actions_options_integration_response" {
  depends_on  = [aws_api_gateway_integration.actions_options_mock]
  rest_api_id = aws_api_gateway_rest_api.team_diamonds_api.id
  resource_id = aws_api_gateway_resource.actions_resource.id
  http_method = aws_api_gateway_method.actions_options.http_method
  status_code = aws_api_gateway_method_response.actions_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}


# /{proxy+} catches all other routes: /auth/login, /auth/callback, /health,
# /chat, /chat-relay, /issues, /docs, /redoc, etc.
resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.team_diamonds_api.id
  parent_id   = aws_api_gateway_rest_api.team_diamonds_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.team_diamonds_api.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE" # No auth — FastAPI handles its own auth internally
}

resource "aws_api_gateway_integration" "proxy_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.team_diamonds_api.id
  resource_id             = aws_api_gateway_resource.proxy_resource.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.action_lambda_invoke_arn
}


# Lambda permission (single permission covers all routes via wildcard source ARN)

resource "aws_lambda_permission" "apigw_action_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.action_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.team_diamonds_api.execution_arn}/*/*"
}


# Add CORS headers to all 4xx errors (like 401 Unauthorized and 403 Forbidden)
resource "aws_api_gateway_gateway_response" "cors_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.team_diamonds_api.id
  response_type = "DEFAULT_4XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

# Add CORS headers to all 5xx errors (Lambda crashes, timeouts, etc.)
resource "aws_api_gateway_gateway_response" "cors_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.team_diamonds_api.id
  response_type = "DEFAULT_5XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}


# Deployment & Stage

resource "aws_api_gateway_deployment" "team_diamonds_deployment" {
  depends_on = [
    aws_api_gateway_integration.actions_lambda_integration,
    aws_api_gateway_integration_response.actions_options_integration_response,
    aws_api_gateway_integration.proxy_lambda_integration,
    aws_api_gateway_authorizer.cognito_auth,
    aws_api_gateway_gateway_response.cors_4xx,
    aws_api_gateway_gateway_response.cors_5xx,
  ]

  rest_api_id = aws_api_gateway_rest_api.team_diamonds_api.id

  # Redeploys when any routing, method, or CORS configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.actions_resource.id,
      aws_api_gateway_method.actions_method.id,
      aws_api_gateway_integration.actions_lambda_integration.id,
      aws_api_gateway_method.actions_options.id,
      aws_api_gateway_integration.actions_options_mock.id,

      aws_api_gateway_resource.proxy_resource.id,
      aws_api_gateway_method.proxy_method.id,
      aws_api_gateway_integration.proxy_lambda_integration.id,
      aws_api_gateway_authorizer.cognito_auth.id,
      aws_api_gateway_gateway_response.cors_4xx.id,
      aws_api_gateway_gateway_response.cors_5xx.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.team_diamonds_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.team_diamonds_api.id
  stage_name    = "prod"
}


resource "aws_ssm_parameter" "api_gateway_url" {
  name        = "team-diamonds-api-url"
  description = "The invoke URL for the Team Diamonds API Gateway"
  type        = "String"
  value       = "https://${aws_api_gateway_rest_api.team_diamonds_api.id}.execute-api.us-east-2.amazonaws.com/${aws_api_gateway_stage.prod_stage.stage_name}"
}
