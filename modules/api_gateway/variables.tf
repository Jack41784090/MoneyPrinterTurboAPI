variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "suffix" {
  description = "Unique suffix for resource names"
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