variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "suffix" {
  description = "Unique suffix for resource names"
  type        = string
}

variable "service_dns_name" {
  description = "The DNS name of the ECS service via service discovery"
  type        = string
}

variable "api_stage_name" {
  description = "The name of the API Gateway stage"
  type        = string
  default     = "prod"
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}