output "alb_dns_name" {
  description = "The DNS name of the application load balancer"
  value       = aws_lb.app.dns_name
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.app.name
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.app.name
}
