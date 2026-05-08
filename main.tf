terraform {
  cloud {
    organization = "Team-Diamonds"

    workspaces {
      name = "team-diamonds-IaC"
    }
  }
}

# main.tf in root directory passes outputs of one module to variables of other modules

module "auth" {
  source = "./modules/auth"
}

module "database" {
  source = "./modules/database"
}

module "compute" {
  source             = "./modules/compute"
  dynamodb_table_arn = module.database.dynamodb_table_arn
}

module "api" {
  source = "./modules/api"

  cognito_user_pool_arn       = module.auth.cognito_user_pool_arn
  oauth_lambda_invoke_arn     = module.compute.oauth_lambda_invoke_arn
  action_lambda_invoke_arn    = module.compute.action_lambda_invoke_arn
  oauth_lambda_function_name  = module.compute.oauth_lambda_function_name
  action_lambda_function_name = module.compute.action_lambda_function_name
}

module "telemetry" {
  source = "./modules/telemetry"

  api_gateway_name = module.api.api_gateway_name
  aws_region       = "us-east-2"
}

#output website endpoint
output "website_endpoint" {
  description = "The URL for visiting website."
  value       = module.compute.website_endpoint
}