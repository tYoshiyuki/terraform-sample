terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "security_group" {
  description = var.sg_alb_name
  name = var.sg_alb_name
  tags = {
    Name = var.sg_alb_name
  }
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
}

resource "aws_security_group" "security_group_ec2" {
  description = var.sg_ec2_name
  name = var.sg_ec2_name
  tags = {
    Name = var.sg_ec2_name
  }
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name = var.auto_scaling_name
  launch_template {
    id = aws_launch_template.launch_template.id
    version = "1"
  }
  min_size = 1
  max_size = 1
  desired_capacity = 1
  default_cooldown = 300
  vpc_zone_identifier = [
    "subnet-fabe92a1",
    "subnet-3681451d",
    "subnet-3945b771"
  ]
  target_group_arns = [
    aws_lb_target_group.lb_target_group.arn
  ]
  health_check_type = "EC2"
  health_check_grace_period = 300
  termination_policies = [
    "Default"
  ]
  service_linked_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  tag {
    key = "Name"
    value = var.auto_scaling_name
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "launch_template" {
  name = var.launch_template_name
  user_data = filebase64("user_data.sh")
  iam_instance_profile {
    arn = aws_iam_instance_profile.iam.arn
  }
  vpc_security_group_ids = [
    aws_security_group.security_group_ec2.id
  ]
  key_name = var.key_name
  image_id = var.image_id
  instance_type = var.instance_type
}

resource "aws_lb" "lb" {
  name = var.alb_name
  internal = false
  load_balancer_type = "application"
  subnets = [
    "subnet-3681451d",
    "subnet-3945b771",
    "subnet-fabe92a1"
  ]
  security_groups = [
    aws_security_group.security_group.id
  ]
  ip_address_type = "ipv4"
  access_logs {
    enabled = false
    bucket = ""
    prefix = ""
  }
  idle_timeout = "60"
  enable_deletion_protection = "false"
  enable_http2 = "true"
  enable_cross_zone_load_balancing = "true"
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    type = "forward"
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  health_check {
    interval = 30
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    timeout = 5
    unhealthy_threshold = 2
    healthy_threshold = 5
    matcher = "200"
  }
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = var.vpc_id
  name = var.tg_name
}
