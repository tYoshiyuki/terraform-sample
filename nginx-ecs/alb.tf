resource "aws_security_group" "alb" {
  name        = local.lb_security_group_name
  description = local.lb_security_group_name

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.lb_security_group_name
  }
}

resource "aws_security_group_rule" "main" {
  security_group_id = aws_security_group.alb.id

  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "lb" {
  load_balancer_type = "application"
  name               = local.lb_name

  security_groups = [aws_security_group.alb.id]
  subnets = [
    var.vpc_subnet1,
    var.vpc_subnet2,
    var.vpc_subnet3
  ]
}

resource "aws_lb_target_group" "main" {
  name   = local.lb_target_group_name
  vpc_id = var.vpc_id

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    port = 80
    path = "/"
  }
}

resource "aws_lb_listener" "main" {
  port     = "80"
  protocol = "HTTP"

  load_balancer_arn = aws_lb.lb.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.main.arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0
      }

      target_group {
        arn    = aws_lb_target_group.canary.arn
        weight = 0
      }

    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb_target_group" "green" {
  name   = "${local.lb_target_group_name}-green"
  vpc_id = var.vpc_id

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path = "/"
    port = 80
  }
}

# resource "aws_lb_target_group" "canary" {
#   name   = "${local.lb_target_group_name}-canary"
#   vpc_id = var.vpc_id

#   port        = 80
#   protocol    = "HTTP"
#   target_type = "ip"

#   health_check {
#     path = "/"
#     port = 80
#   }
# }