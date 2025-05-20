variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "suffix" {
  description = "Unique suffix for resource names"
  type        = string
}

variable "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  type        = string
}

variable "api_stage_name" {
  description = "The name of the API Gateway stage"
  type        = string
  default     = "prod"
}