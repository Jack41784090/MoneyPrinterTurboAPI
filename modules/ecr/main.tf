# ECR Repository to store the Docker image
resource "aws_ecr_repository" "app" {
  name         = "${var.app_name}-${var.suffix}"
  force_delete = true
  
  image_scanning_configuration {
    scan_on_push = true
  }
}