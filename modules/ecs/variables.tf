variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "suffix" {
  description = "Unique suffix for resource names"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
}

variable "container_image" {
  description = "The container image to use"
  type        = string
}

variable "container_cpu" {
  description = "The amount of CPU to allocate to the container"
  type        = number
}

variable "container_memory" {
  description = "The amount of memory to allocate to the container"
  type        = number
}

variable "service_desired_count" {
  description = "The number of instances of the task to place and keep running"
  type        = number
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "ecs_security_group_id" {
  description = "The ID of the security group for the ECS service"
  type        = string
}

variable "alb_security_group_id" {
  description = "The ID of the security group for the ALB"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  type        = string
}
