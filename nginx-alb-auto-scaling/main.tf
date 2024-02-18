resource "aws_security_group" "alb" {
  description = local.sg_alb_name
  name        = local.sg_alb_name
  tags = {
    Name = local.sg_alb_name
  }
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
}

resource "aws_security_group" "ec2" {
  description = local.sg_ec2_name
  name        = local.sg_ec2_name
  tags = {
    Name = local.sg_ec2_name
  }
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
}

resource "aws_autoscaling_group" "main" {
  name = local.auto_scaling_name
  launch_template {
    id      = aws_launch_template.main.id
    version = "1"
  }
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  default_cooldown = 300
  vpc_zone_identifier = [
    var.vpc_subnet1,
    var.vpc_subnet2,
    var.vpc_subnet3
  ]
  target_group_arns = [
    aws_lb_target_group.main.arn
  ]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies = [
    "Default"
  ]
  service_linked_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  tag {
    key                 = "Name"
    value               = local.auto_scaling_name
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "canary" {
  name = "${local.auto_scaling_name}-canary"
  launch_template {
    id      = aws_launch_template.main.id
    version = "1"
  }
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  default_cooldown = 300
  vpc_zone_identifier = [
    var.vpc_subnet1,
    var.vpc_subnet2,
    var.vpc_subnet3
  ]
  target_group_arns = [
    aws_lb_target_group.canary.arn
  ]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies = [
    "Default"
  ]
  service_linked_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  tag {
    key                 = "Name"
    value               = "${local.auto_scaling_name}-canary"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "main" {
  name      = local.launch_template_name
  user_data = filebase64("user_data.sh")
  iam_instance_profile {
    arn = aws_iam_instance_profile.iam.arn
  }
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  key_name      = aws_key_pair.key_pair.key_name
  image_id      = local.image_id
  instance_type = local.instance_type
}

resource "aws_lb" "main" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  subnets = [
    var.vpc_subnet1,
    var.vpc_subnet2,
    var.vpc_subnet3
  ]
  security_groups = [
    aws_security_group.alb.id
  ]
  ip_address_type = "ipv4"
  access_logs {
    enabled = false
    bucket  = ""
    prefix  = ""
  }
  idle_timeout                     = "60"
  enable_deletion_protection       = "false"
  enable_http2                     = "true"
  enable_cross_zone_load_balancing = "true"
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.main.arn
        weight = 2
      }
      target_group {
        arn    = aws_lb_target_group.canary.arn
        weight = 1
      }
    }
  }
}

resource "aws_lb_target_group" "main" {
  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 5
    matcher             = "200"
  }
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  name        = local.tg_name
}

resource "aws_lb_target_group" "canary" {
  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 5
    matcher             = "200"
  }
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  name        = "${local.tg_name}-canary"
}
