# Get current AWS region
data "aws_region" "current" {}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# CloudWatch role for API Gateway (required for logging)
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.app_name}-api-gateway-cloudwatch-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-api-gateway-cloudwatch-role"
    Environment = var.environment
  }
}

# Attach the managed policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Set the CloudWatch role ARN at the account level
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn

  depends_on = [aws_iam_role_policy_attachment.api_gateway_cloudwatch]
}

# API Gateway and IAM Authentication
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.app_name}-api-${var.suffix}"
  description = "${var.app_name} API with IAM Authentication"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway Resource
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method - ANY
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "AWS_IAM"
}

# For cost optimization, we'll use a mock integration that returns connection info
# The client will need to connect directly to the ECS service's public IP
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "MOCK"
  
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# Integration Response for proxy
resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy_200.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "ECS Service endpoint - connect directly via service discovery or public IP"
      service = var.app_name
      status = "active"
    })
  }
}

# API Gateway Root Resource Method - ANY
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "ANY"
  authorization = "AWS_IAM"
}

# API Gateway Root Resource Integration (mock integration)
resource "aws_api_gateway_integration" "proxy_root" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_rest_api.api.root_resource_id
  http_method             = aws_api_gateway_method.proxy_root.http_method
  integration_http_method = "POST"
  type                    = "MOCK"
  
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# Integration Response for proxy root
resource "aws_api_gateway_integration_response" "proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method
  status_code = aws_api_gateway_method_response.proxy_root_200.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "MoneyPrinterTurbo API - Cost-Optimized Version"
      service = var.app_name
      version = "v1.0"
      endpoints = {
        ping = "/v1/ping"
        videos = "/v1/videos"
        generate = "/v1/generate"
      }
      note = "Connect directly to ECS service for API calls"
    })
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_integration.proxy,
    aws_api_gateway_integration.proxy_root,
    aws_api_gateway_integration_response.proxy,
    aws_api_gateway_integration_response.proxy_root
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }
  # Force new deployment when methods change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_method.proxy_root.id,
      aws_api_gateway_integration.proxy.id,
      aws_api_gateway_integration.proxy_root.id,
      aws_api_gateway_integration_response.proxy.id,
      aws_api_gateway_integration_response.proxy_root.id,
    ]))
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.api_stage_name

  # Enable logging and monitoring
  xray_tracing_enabled = true

  depends_on = [
    aws_api_gateway_account.api_gateway_account,
    aws_cloudwatch_log_group.api_gateway
  ]

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
      errorType      = "$context.error.messageString"
      authType       = "$context.identity.authType"
      principalId    = "$context.authorizer.principalId"
    })
  }

  tags = {
    Name = "${var.app_name}-api-stage-${var.api_stage_name}"
    Environment = var.environment
  }
}

# CloudWatch Log Group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.app_name}-${var.suffix}"
  retention_in_days = 14

  tags = {
    Name = "${var.app_name}-api-gateway-logs"
    Environment = var.environment
  }
}

# Method Response for better error handling
resource "aws_api_gateway_method_response" "proxy_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_method_response" "proxy_401" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "401"
}

resource "aws_api_gateway_method_response" "proxy_403" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "403"
}

resource "aws_api_gateway_method_response" "proxy_root_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_method_response" "proxy_root_401" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method
  status_code = "401"
}

resource "aws_api_gateway_method_response" "proxy_root_403" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method
  status_code = "403"
}