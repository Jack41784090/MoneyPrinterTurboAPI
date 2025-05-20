output "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "api_user_name" {
  description = "The name of the API user"
  value       = aws_iam_user.api_user.name
}

output "api_access_key_id" {
  description = "The access key ID for the API user"
  value       = aws_iam_access_key.api_user.id
  sensitive   = true
}

output "api_secret_access_key" {
  description = "The secret access key for the API user"
  value       = aws_iam_access_key.api_user.secret
  sensitive   = true
}