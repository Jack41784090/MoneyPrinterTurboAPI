terraform {
  backend "s3" {
    # These values will be provided via -backend-config during terraform init
    # bucket         = "your-terraform-state-bucket"
    # key            = "terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "your-terraform-locks-table"
    # encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Main Terraform configuration file for MoneyPrinterTurboAPI
# AWS Provider configuration
# Credentials can be provided via:
# 1. AWS CLI: Run `aws configure` to set up credentials
# 2. Environment variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# 3. IAM roles (when running on EC2)
# 4. Shared credentials file (~/.aws/credentials)
provider "aws" {
  region = var.aws_region
  
  # Optional: Uncomment and set if you want to use a specific AWS CLI profile
  # profile = "ikec-root-admin"
  
  # Optional: Uncomment if you want to specify credentials directly (not recommended for production)
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}

# Generate a unique suffix for resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# ECR Repository
module "ecr" {
  source = "./modules/ecr"
  
  app_name = var.app_name
  suffix   = random_string.suffix.result
}

# Storage (S3)
module "storage" {
  source = "./modules/storage"
  
  app_name            = var.app_name
  suffix              = random_string.suffix.result
  storage_bucket_name = var.storage_bucket_name
}

# Networking
module "networking" {
  source = "./modules/networking"
  
  app_name = var.app_name
  suffix   = random_string.suffix.result
}

# IAM Roles and Policies
module "iam" {
  source = "./modules/iam"
  
  app_name                   = var.app_name
  suffix                     = random_string.suffix.result
  storage_bucket_name        = module.storage.bucket_name
  storage_bucket_arn         = module.storage.bucket_arn
  api_gateway_execution_arn  = module.api_gateway.api_gateway_execution_arn
  environment               = var.environment
}

# ECS Service (created first to provide service DNS)
module "ecs" {
  source = "./modules/ecs"
  
  app_name                  = var.app_name
  suffix                    = random_string.suffix.result
  aws_region                = var.aws_region
  container_image           = "${module.ecr.repository_url}:latest"
  container_cpu             = var.container_cpu
  container_memory          = var.container_memory
  service_desired_count     = var.service_desired_count
  vpc_id                    = module.networking.vpc_id
  subnet_ids                = module.networking.public_subnet_ids
  s3_bucket_name            = module.storage.bucket_name
  ecs_security_group_id     = module.networking.ecs_security_group_id
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn         = module.iam.ecs_task_role_arn
}

# API Gateway (Create without load balancer for cost optimization)
module "api_gateway" {
  source = "./modules/api_gateway"
  
  app_name                      = var.app_name
  suffix                        = random_string.suffix.result
  api_stage_name                = var.api_stage_name
  environment                   = var.environment
}

# API Gateway Resource Policy (applied after IAM roles are created)
data "aws_iam_policy_document" "api_gateway_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        module.iam.api_admin_role_arn,
        module.iam.api_user_role_arn,
        module.iam.api_readonly_role_arn
      ]
    }
    actions = ["execute-api:Invoke"]
    resources = ["${module.api_gateway.api_gateway_execution_arn}/*"]
  }
}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
  rest_api_id = module.api_gateway.api_gateway_id
  policy      = data.aws_iam_policy_document.api_gateway_policy.json
  
  depends_on = [
    module.iam,
    module.api_gateway
  ]
}

# Additional IAM Policy for API Gateway Access (created after API Gateway)
resource "aws_iam_policy" "api_gateway_policy" {
  name        = "${var.app_name}-api-gateway-policy-${random_string.suffix.result}"
  description = "Policy to allow access to ${var.app_name} API Gateway"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "execute-api:Invoke"
        ]
        Effect   = "Allow"
        Resource = "${module.api_gateway.api_gateway_execution_arn}/${var.api_stage_name}/*/*"
      }
    ]
  })
}

# Attach API Gateway Policy to API User (Legacy - for backward compatibility)
resource "aws_iam_user_policy_attachment" "api_gateway_user_policy" {
  user       = module.iam.api_user_name
  policy_arn = aws_iam_policy.api_gateway_policy.arn
}

# Outputs
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "api_endpoint" {
  description = "The API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "aws_region" {
  description = "The AWS region used for deployment"
  value       = var.aws_region
}

output "storage_bucket_name" {
  description = "The name of the S3 storage bucket"
  value       = module.storage.bucket_name
}

output "unique_suffix" {
  description = "The unique suffix used for resource names"
  value       = random_string.suffix.result
}

# Role-Based Access Control Outputs
output "api_admin_role_arn" {
  description = "ARN of the API admin role (full access)"
  value       = module.iam.api_admin_role_arn
}

output "api_user_role_arn" {
  description = "ARN of the API user role (read/write, no admin)"
  value       = module.iam.api_user_role_arn
}

output "api_readonly_role_arn" {
  description = "ARN of the API readonly role (read-only)"
  value       = module.iam.api_readonly_role_arn
}

output "role_usage_instructions" {
  description = "Instructions for using role-based access"
  value = <<-EOT
    Role-Based Access Control Setup Complete!
    
    Available Roles:
    1. Admin Role: ${module.iam.api_admin_role_arn}
       - Full API access (all endpoints)
       - S3 read/write/delete access
       - External ID: ${var.app_name}-admin-${random_string.suffix.result}
    
    2. User Role: ${module.iam.api_user_role_arn}
       - API read/write access (no admin endpoints)
       - S3 read/write access (no delete)
       - External ID: ${var.app_name}-user-${random_string.suffix.result}
    
    3. Read-Only Role: ${module.iam.api_readonly_role_arn}
       - API read-only access (GET requests only)
       - S3 read-only access
       - External ID: ${var.app_name}-readonly-${random_string.suffix.result}
    
    Usage Examples:
    
    PowerShell (Windows):
    .\scripts\assume_role.ps1 -Role "admin" -Suffix "${random_string.suffix.result}"
    
    Python API Client:
    python scripts/api_access_helper.py --role admin --action list_videos --api-endpoint "${module.api_gateway.api_endpoint}" --suffix "${random_string.suffix.result}"
    
    AWS CLI (after assuming role):
    aws sts assume-role --role-arn ${module.iam.api_admin_role_arn} --role-session-name MySession --external-id ${var.app_name}-admin-${random_string.suffix.result}
  EOT
}

# Legacy outputs (deprecated but kept for backward compatibility)
output "api_user_access_key_id" {
  description = "The access key ID for the API user (DEPRECATED - use roles instead)"
  value       = module.iam.api_access_key_id
  sensitive   = true
}

output "api_user_secret_access_key" {
  description = "The secret access key for the API user (DEPRECATED - use roles instead)"
  value       = module.iam.api_secret_access_key
  sensitive   = true
}
