# -------------------------------------------------------------------
# NLB
# -------------------------------------------------------------------
resource "aws_security_group" "nlb" {
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
  security_group_id = aws_security_group.nlb.id

  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "lb" {
  load_balancer_type               = "network"
  name                             = local.lb_name
  internal                         = true
  enable_cross_zone_load_balancing = "true"

  security_groups = [aws_security_group.nlb.id]
  subnets = [
    var.vpc_subnet1,
    var.vpc_subnet2,
    var.vpc_subnet3
  ]
}

resource "aws_lb_target_group" "main" {
  name                 = local.lb_target_group_name
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  port     = 80
  protocol = "TCP"

  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
  }
}

resource "aws_lb_target_group" "sub" {
  name                 = local.lb_target_group_sub_name
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  port     = 80
  protocol = "TCP"

  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
  }
}

resource "aws_lb_listener" "main" {
  port     = "80"
  protocol = "TCP"

  load_balancer_arn = aws_lb.lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
