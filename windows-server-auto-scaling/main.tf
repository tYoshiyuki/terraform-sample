data "aws_caller_identity" "current" {}

resource "aws_security_group" "main" {
  description = local.sg_name
  name        = local.sg_name
  tags = {
    Name = local.sg_name
  }
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 3389
    protocol  = "tcp"
    to_port   = 3389
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
  name = local.windows_server_auto_scaling
  launch_template {
    id      = aws_launch_template.main.id
    version = "1"
  }
  min_size         = 1
  max_size         = 1
  desired_capacity = 0
  default_cooldown = 300
  availability_zones = [
    "ap-northeast-1c"
  ]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies = [
    "Default"
  ]
  service_linked_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  tag {
    key                 = "Name"
    value               = local.windows_server_auto_scaling
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "main" {
  name = local.windows_server_launch_template
  iam_instance_profile {
    arn = aws_iam_instance_profile.main.arn
  }
  vpc_security_group_ids = [
    aws_security_group.main.id
  ]
  key_name      = aws_key_pair.key_pair.key_name
  image_id      = data.aws_ami.windows-2019.id
  instance_type = local.instance_type
}

data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-Japanese-Full-Base*"]
  }
}
