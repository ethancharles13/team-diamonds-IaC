resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Team-Diamonds-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "API Gateway - Traffic (Count)"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "API Gateway - Latency"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", var.api_gateway_name],
            [".", "IntegrationLatency", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 8
        height = 6
        properties = {
          title   = "API Gateway - Success Rate"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          metrics = [
            # Base Metrics (Hidden from view)
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name, { "id" : "requests", "stat" : "Sum", "visible" : false }],
            [".", "4XXError", ".", ".", { "id" : "errors4xx", "stat" : "Sum", "visible" : false }],
            [".", "5XXError", ".", ".", { "id" : "errors5xx", "stat" : "Sum", "visible" : false }],

            # Metric Math Expression (Visible)
            [{
              "expression" : "100 - (100 * (FILL(errors4xx, 0) + FILL(errors5xx, 0)) / requests)",
              "label" : "Success Rate (%)",
              "id" : "success_rate"
            }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 8
        width  = 8
        height = 6
        properties = {
          title   = "API Gateway - Failure Rate"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          metrics = [
            # Base Metrics (Hidden from view)
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name, { "id" : "requests", "stat" : "Sum", "visible" : false }],
            [".", "4XXError", ".", ".", { "id" : "errors4xx", "stat" : "Sum", "visible" : false }],
            [".", "5XXError", ".", ".", { "id" : "errors5xx", "stat" : "Sum", "visible" : false }],

            # Metric Math Expression (Visible)
            [{
              "expression" : "100 * ((FILL(errors4xx, 0) + FILL(errors5xx, 0)) / requests)",
              "label" : "Error Rate (%)",
              "id" : "error_rate"
            }]
          ]
        }
      },
    ]
  })
}