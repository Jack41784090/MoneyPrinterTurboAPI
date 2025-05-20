# Main Terraform configuration file for MoneyPrinterTurboAPI
provider "aws" {
  region = var.aws_region
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
  
  app_name            = var.app_name
  suffix              = random_string.suffix.result
  storage_bucket_name = module.storage.bucket_name
  storage_bucket_arn  = module.storage.bucket_arn
  
  # API Gateway execution ARN will be added after API Gateway module creation
  api_gateway_execution_arn = ""
  api_stage_name            = var.api_stage_name
}

# ECS Service
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
  alb_security_group_id     = module.networking.alb_security_group_id
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn         = module.iam.ecs_task_role_arn
}

# API Gateway
module "api_gateway" {
  source = "./modules/api_gateway"
  
  app_name       = var.app_name
  suffix         = random_string.suffix.result
  alb_dns_name   = module.ecs.alb_dns_name
  api_stage_name = var.api_stage_name
}

# Update IAM module with API Gateway execution ARN
module "iam_update" {
  source = "./modules/iam"
  
  app_name                  = var.app_name
  suffix                    = random_string.suffix.result
  storage_bucket_name       = module.storage.bucket_name
  storage_bucket_arn        = module.storage.bucket_arn
  api_gateway_execution_arn = module.api_gateway.api_gateway_execution_arn
  api_stage_name            = var.api_stage_name
}

# Add a stage to API Gateway deployment
resource "aws_api_gateway_stage" "api" {
  deployment_id = module.api_gateway.api_gateway_deployment_id
  rest_api_id   = module.api_gateway.api_gateway_id
  stage_name    = var.api_stage_name
}

# Outputs
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "api_endpoint" {
  description = "The API Gateway endpoint URL"
  value       = "${module.api_gateway.api_endpoint}${var.api_stage_name}"
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "aws_region" {
  description = "The AWS region used for deployment"
  value       = var.aws_region
}

output "storage_bucket_name" {
  description = "The name of the S3 storage bucket"
  value       = module.storage.bucket_name
}

output "api_user_access_key_id" {
  description = "The access key ID for the API user"
  value       = module.iam_update.api_access_key_id
  sensitive   = true
}

output "api_user_secret_access_key" {
  description = "The secret access key for the API user"
  value       = module.iam_update.api_secret_access_key
  sensitive   = true
}
