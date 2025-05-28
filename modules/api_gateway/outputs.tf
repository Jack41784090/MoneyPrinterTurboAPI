output "api_gateway_id" {
  description = "The ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.api.execution_arn
}

output "api_endpoint" {
  description = "The API Gateway endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.api.stage_name}"
}

output "stage_name" {
  description = "The name of the API Gateway stage"
  value       = var.api_stage_name
}

output "api_gateway_deployment_id" {
  description = "The ID of the API Gateway deployment"
  value       = aws_api_gateway_deployment.api.id
}