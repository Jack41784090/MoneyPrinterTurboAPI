# ECS Cluster
resource "aws_ecs_cluster" "app" {
  name = "${var.app_name}-cluster-${var.suffix}"

  tags = {
    Name = "${var.app_name}-cluster-${var.suffix}"
    Environment = "production"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}-${var.suffix}"
  retention_in_days = 30

  tags = {
    Name = "${var.app_name}-logs"
    Environment = "production"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.suffix}"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.container_image
      essential = true

      environment = [
        {
          name  = "LISTEN_HOST"
          value = "0.0.0.0"
        },
        {
          name  = "LISTEN_PORT"
          value = "8000"
        },
        {
          name  = "STORAGE_TYPE"
          value = "s3"
        },
        {
          name  = "S3_BUCKET"
          value = var.s3_bucket_name
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8000/v1/ping || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.app_name}-task-definition"
    Environment = "production"
  }
}

# ECS Service (Simplified - no service discovery to avoid Route53 permissions)
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-service-${var.suffix}"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1  # Single task for cost optimization
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true  # Required for API Gateway to reach ECS directly
  }

  # Deployment configuration for rolling updates
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  tags = {
    Name = "${var.app_name}-service"
    Environment = "production"
  }
}


