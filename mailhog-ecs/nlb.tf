resource "aws_security_group" "nlb" {
  name        = local.lb_security_group_name
  description = local.lb_security_group_name

  vpc_id = var.vpc_id

  ingress {
    from_port   = 1025
    to_port     = 1025
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8025
    to_port     = 8025
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_lb" "lb" {
  load_balancer_type = "network"
  name               = local.lb_name

  security_groups = [aws_security_group.nlb.id]
  subnets = [
    var.vpc_subnet1,
    var.vpc_subnet2,
    var.vpc_subnet3
  ]
}

resource "aws_lb_target_group" "main" {
  name   = local.lb_target_group_name
  vpc_id = var.vpc_id

  port        = 8025
  protocol    = "TCP"
  target_type = "ip"

  health_check {
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "main" {
  port     = 8025
  protocol = "TCP"

  load_balancer_arn = aws_lb.lb.arn

  default_action {
    target_group_arn = aws_lb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "smtp" {
  name   = "${local.lb_target_group_name}-smtp"
  vpc_id = var.vpc_id

  port        = 1025
  protocol    = "TCP"
  target_type = "ip"

  health_check {
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "smtp" {
  port     = 1025
  protocol = "TCP"

  load_balancer_arn = aws_lb.lb.arn

  default_action {
    target_group_arn = aws_lb_target_group.smtp.id
    type             = "forward"
  }
}
