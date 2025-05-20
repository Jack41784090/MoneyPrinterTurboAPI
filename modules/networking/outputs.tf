output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "alb_security_group_id" {
  description = "The ID of the security group for the ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "The ID of the security group for the ECS service"
  value       = aws_security_group.ecs_service.id
}