# VPC for the ECS Service
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.app_name}-vpc-${var.suffix}"
  }
}

# Data source for available AZs
data "aws_availability_zones" "available" {}

# Create public subnets in different AZs
resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-public-subnet-${count.index + 1}-${var.suffix}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw-${var.suffix}"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.app_name}-public-rt-${var.suffix}"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for ECS Service (API Gateway VPC Link access only)
resource "aws_security_group" "ecs_service" {
  name        = "${var.app_name}-ecs-sg-${var.suffix}"
  description = "Allow inbound traffic to ${var.app_name} from API Gateway VPC Link"
  vpc_id      = aws_vpc.main.id

  # Allow traffic from API Gateway VPC Link (within VPC only)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # Only allow traffic from within VPC
    description = "API Gateway VPC Link access"
  }

  # Allow all outbound traffic for ECS tasks
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.app_name}-ecs-sg-${var.suffix}"
    Purpose = "ECS-Service-Security"
  }
}