# -------------------------------------------------------------------
# ALB
# -------------------------------------------------------------------
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

  port     = 80
  protocol = "HTTP"

  health_check {
    port = "traffic-port"
    path = "/"
  }
}

resource "aws_lb_target_group" "sub" {
  name   = local.lb_target_group_sub_name
  vpc_id = var.vpc_id

  port     = 80
  protocol = "HTTP"

  health_check {
    port = "traffic-port"
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
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
