resource "aws_ecs_task_definition" "main" {
  family                   = local.ecs_task_definition_name
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  container_definitions    = file("./container_definitions.json")
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.main.arn
}

resource "aws_ecs_cluster" "main" {
  name = local.ecs_cluster_name
}

resource "aws_security_group" "main" {
  name        = local.ecs_security_group_name
  description = local.ecs_security_group_name

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.ecs_security_group_name
  }
}

resource "aws_ecs_service" "main" {
  name                               = local.ecs_service_name
  cluster                            = aws_ecs_cluster.main.arn
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  propagate_tags                     = "SERVICE"
  enable_execute_command             = true
  launch_type                        = "FARGATE"
  desired_count                      = "1"
  task_definition                    = aws_ecs_task_definition.main.arn

  health_check_grace_period_seconds = 60
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    assign_public_ip = true
    subnets = [
      var.vpc_subnet1,
      var.vpc_subnet2,
      var.vpc_subnet3
    ]
    security_groups = [aws_security_group.alb.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = "80"
  }
}

resource "aws_iam_role" "task_execution_role" {
  name = local.task_execution_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
}

resource "aws_iam_role" "main" {
  name = local.task_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "main" {
  name   = local.task_role_policy_name
  policy = file("./policy.json")
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attachment" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}
