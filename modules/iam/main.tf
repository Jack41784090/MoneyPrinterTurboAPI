# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-execution-role-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonECSTaskExecutionRolePolicy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-task-role-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM policy for the ECS task to interact with S3
resource "aws_iam_policy" "task_s3_policy" {
  name        = "${var.app_name}-s3-policy-${var.suffix}"
  description = "Allow ${var.app_name} to interact with S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          var.storage_bucket_arn,
          "${var.storage_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to ECS task role
resource "aws_iam_role_policy_attachment" "task_s3_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_s3_policy.arn
}

# IAM User for API Access
resource "aws_iam_user" "api_user" {
  name = "${var.app_name}-api-user-${var.suffix}"
}

# IAM Policy for API Access
resource "aws_iam_policy" "api_policy" {
  count = var.api_gateway_execution_arn != "" ? 1 : 0
  
  name        = "${var.app_name}-api-policy-${var.suffix}"
  description = "Policy to allow access to ${var.app_name} API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "execute-api:Invoke"
        ]
        Effect   = "Allow"
        Resource = "${var.api_gateway_execution_arn}/${var.api_stage_name}/*/*"
      }
    ]
  })
}

# Attach API Policy to User
resource "aws_iam_user_policy_attachment" "api_user_policy" {
  count = var.api_gateway_execution_arn != "" ? 1 : 0
  
  user       = aws_iam_user.api_user.name
  policy_arn = aws_iam_policy.api_policy[0].arn
}

# Access Key for API User
resource "aws_iam_access_key" "api_user" {
  user = aws_iam_user.api_user.name
}