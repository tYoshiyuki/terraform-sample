resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = local.ecs_task_definition_name
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  container_definitions    = file("./container_definitions.json")
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = local.ecs_cluster_name
}

resource "aws_security_group" "ecs_security_group" {
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

resource "aws_ecs_service" "ecs_service" {
  name                               = local.ecs_service_name
  cluster                            = aws_ecs_cluster.ecs_cluster.arn
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  propagate_tags                     = "SERVICE"
  enable_execute_command             = true
  launch_type                        = "FARGATE"
  desired_count                      = "1"
  task_definition                    = aws_ecs_task_definition.ecs_task_definition.arn

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
    security_groups = [aws_security_group.ecs_security_group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "nginx"
    container_port   = "80"
  }
}