variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "The name of the application"
  type        = string
  default     = "moneyprinterturbo"
}

variable "storage_bucket_name" {
  description = "The name of the S3 bucket for storing MoneyPrinterTurbo files"
  type        = string
  default     = ""  # If left empty, a name will be auto-generated
}

variable "container_cpu" {
  description = "The amount of CPU to allocate to the container (in CPU units)"
  type        = number
  default     = 1024  # 1 vCPU
}

variable "container_memory" {
  description = "The amount of memory to allocate to the container (in MiB)"
  type        = number
  default     = 2048  # 2 GB
}

variable "service_desired_count" {
  description = "The number of instances of the task to place and keep running"
  type        = number
  default     = 1
}

variable "api_stage_name" {
  description = "The name of the API Gateway stage"
  type        = string
  default     = "prod"
}