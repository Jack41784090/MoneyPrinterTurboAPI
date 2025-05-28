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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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

# API Gateway Resource-based Policy Data
data "aws_iam_policy_document" "api_gateway_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.api_admin_role.arn,
        aws_iam_role.api_user_role.arn,
        aws_iam_role.api_readonly_role.arn
      ]
    }
    actions = ["execute-api:Invoke"]
    resources = ["${var.api_gateway_execution_arn}/*"]
  }
}

# IAM Role for API Administrators (Full Access)
resource "aws_iam_role" "api_admin_role" {
  name = "${var.app_name}-api-admin-role-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "${var.app_name}-admin-${var.suffix}"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-api-admin-role"
    Environment = var.environment
    AccessLevel = "admin"
  }
}

# IAM Role for API Regular Users (Read/Write Access)
resource "aws_iam_role" "api_user_role" {
  name = "${var.app_name}-api-user-role-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "${var.app_name}-user-${var.suffix}"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-api-user-role"
    Environment = var.environment
    AccessLevel = "user"
  }
}

# IAM Role for API Read-Only Users
resource "aws_iam_role" "api_readonly_role" {
  name = "${var.app_name}-api-readonly-role-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "${var.app_name}-readonly-${var.suffix}"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-api-readonly-role"
    Environment = var.environment
    AccessLevel = "readonly"
  }
}

# Policy for API Admin Role (Full API Access)
resource "aws_iam_policy" "api_admin_policy" {
  name = "${var.app_name}-api-admin-policy-${var.suffix}"
  description = "Full access policy for API administrators"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${var.api_gateway_execution_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          var.storage_bucket_arn,
          "${var.storage_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Policy for API User Role (Read/Write Access, No Admin Operations)
resource "aws_iam_policy" "api_user_policy" {
  name = "${var.app_name}-api-user-policy-${var.suffix}"
  description = "Read/Write access policy for regular API users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${var.api_gateway_execution_arn}/*/GET/*",
        Condition = {
          StringNotLike = {
            "execute-api:Request/proxy" = ["admin/*", "system/*"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${var.api_gateway_execution_arn}/*/POST/*",
        Condition = {
          StringNotLike = {
            "execute-api:Request/proxy" = ["admin/*", "system/*"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.storage_bucket_arn,
          "${var.storage_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Policy for API Read-Only Role
resource "aws_iam_policy" "api_readonly_policy" {
  name = "${var.app_name}-api-readonly-policy-${var.suffix}"
  description = "Read-only access policy for API readonly users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${var.api_gateway_execution_arn}/*/GET/*",
        Condition = {
          StringNotLike = {
            "execute-api:Request/proxy" = ["admin/*", "system/*"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.storage_bucket_arn,
          "${var.storage_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "api_admin_policy_attachment" {
  role       = aws_iam_role.api_admin_role.name
  policy_arn = aws_iam_policy.api_admin_policy.arn
}

resource "aws_iam_role_policy_attachment" "api_user_policy_attachment" {
  role       = aws_iam_role.api_user_role.name
  policy_arn = aws_iam_policy.api_user_policy.arn
}

resource "aws_iam_role_policy_attachment" "api_readonly_policy_attachment" {
  role       = aws_iam_role.api_readonly_role.name
  policy_arn = aws_iam_policy.api_readonly_policy.arn
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# IAM User for API Access (Deprecated - keeping for backward compatibility)
resource "aws_iam_user" "api_user" {
  name = "${var.app_name}-api-user-${var.suffix}"
  
  tags = {
    Name = "${var.app_name}-api-user"
    Environment = var.environment
    Status = "deprecated"
    Note = "Use IAM roles instead of users for API access"
  }
}

# Access Key for API User (Deprecated - keeping for backward compatibility)
resource "aws_iam_access_key" "api_user" {
  user = aws_iam_user.api_user.name
}