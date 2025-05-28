output "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

# API Role-Based Access Control Outputs
output "api_admin_role_arn" {
  description = "The ARN of the API admin role"
  value       = aws_iam_role.api_admin_role.arn
}

output "api_user_role_arn" {
  description = "The ARN of the API user role"
  value       = aws_iam_role.api_user_role.arn
}

output "api_readonly_role_arn" {
  description = "The ARN of the API readonly role"
  value       = aws_iam_role.api_readonly_role.arn
}

output "api_admin_role_name" {
  description = "The name of the API admin role"
  value       = aws_iam_role.api_admin_role.name
}

output "api_user_role_name" {
  description = "The name of the API user role"
  value       = aws_iam_role.api_user_role.name
}

output "api_readonly_role_name" {
  description = "The name of the API readonly role"
  value       = aws_iam_role.api_readonly_role.name
}

output "api_gateway_policy_document" {
  description = "The IAM policy document for API Gateway resource policy"
  value       = data.aws_iam_policy_document.api_gateway_policy.json
}

# Legacy outputs (deprecated but kept for backward compatibility)
output "api_user_name" {
  description = "The name of the API user (DEPRECATED - use roles instead)"
  value       = aws_iam_user.api_user.name
}

output "api_access_key_id" {
  description = "The access key ID for the API user (DEPRECATED - use roles instead)"
  value       = aws_iam_access_key.api_user.id
  sensitive   = true
}

output "api_secret_access_key" {
  description = "The secret access key for the API user (DEPRECATED - use roles instead)"
  value       = aws_iam_access_key.api_user.secret
  sensitive   = true
}