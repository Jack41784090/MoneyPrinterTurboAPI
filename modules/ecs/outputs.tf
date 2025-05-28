output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.app.name
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "service_discovery_service_arn" {
  description = "The ARN of the service discovery service"
  value       = aws_service_discovery_service.app.arn
}

output "service_discovery_namespace_id" {
  description = "The ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.app.id
}

output "service_dns_name" {
  description = "The DNS name for the service"
  value       = "${var.app_name}.${aws_service_discovery_private_dns_namespace.app.name}"
}