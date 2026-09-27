# ==============================================================================
# AWS ECS Cluster (Fargate) + Sample Micro Service
# ==============================================================================

# 1. CloudWatch Log Group for ECS container logs
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 1

  tags = {
    Name = "${var.project_name}-ecs-logs"
  }
}

# 2. ECS Cluster definition
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
}

# 3. Capacity Providers: Fargate & Fargate Spot
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
}

# 4. Lightweight Task Definition (Alpine Nginx)
resource "aws_ecs_task_definition" "sample_app" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "demo-container"
      image     = "public.ecr.aws/docker/library/nginx:alpine"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "container"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-task-def"
  }
}

# 5. ECS Fargate Service
resource "aws_ecs_service" "sample_service" {
  count           = var.enable_ecs_sample_service ? 1 : 0
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sample_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public[0].id, aws_subnet.public[1].id]
    security_groups  = [aws_security_group.cluster_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy,
    aws_cloudwatch_log_group.ecs_logs
  ]

  tags = {
    Name = "${var.project_name}-ecs-service"
  }
}