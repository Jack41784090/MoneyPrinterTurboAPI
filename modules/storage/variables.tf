variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "suffix" {
  description = "Unique suffix for resource names"
  type        = string
}

variable "storage_bucket_name" {
  description = "The name of the S3 bucket for storage"
  type        = string
  default     = ""
}