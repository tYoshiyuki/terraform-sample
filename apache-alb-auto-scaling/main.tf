# -------------------------------------------------------------------
# Security Group
# -------------------------------------------------------------------
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

# -------------------------------------------------------------------
# Autoscaling Group (main + canary)
# -------------------------------------------------------------------
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
    interval            = 5
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 2
    unhealthy_threshold = 2
    healthy_threshold   = 2
    matcher             = "200"
  }
  deregistration_delay = 10
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  name                 = local.tg_name
}

resource "aws_lb_target_group" "canary" {
  health_check {
    interval            = 5
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 2
    unhealthy_threshold = 2
    healthy_threshold   = 2
    matcher             = "200"
  }
  deregistration_delay = 10
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  name                 = "${local.tg_name}-canary"
}

# -------------------------------------------------------------------
# Code Pipeline, Code Deploy
# -------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  bucket        = local.s3_name
  force_destroy = true
}

resource "aws_s3_object" "main" {
  bucket = aws_s3_bucket.main.id
  key    = "SampleApp_Linux.zip"
  source = "${path.module}/SampleApp_Linux.zip"
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_codedeploy_app" "main" {
  name             = local.code_deploy_app_name
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "in_place" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = local.codedeploy_deployment_group_name
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CodeDeployRole"
  autoscaling_groups     = [aws_autoscaling_group.main.name]

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.main.name
    }
  }
}

resource "aws_codedeploy_deployment_group" "bg" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = local.codedeploy_deployment_group_bg_name
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CodeDeployRole"
  autoscaling_groups     = [aws_autoscaling_group.main.name]

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.main.name
    }
  }
}

resource "aws_codepipeline" "main" {
  name     = local.codepipeline_name
  role_arn = aws_iam_role.iam_codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.main.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      configuration = {
        PollForSourceChanges = "true"
        S3Bucket             = aws_s3_bucket.main.bucket
        S3ObjectKey          = "SampleApp_Linux.zip"
      }
      provider = "S3"
      version  = "1"
      output_artifacts = [
        "SourceArtifact"
      ]
      run_order = 1
    }
  }
  stage {
    name = "Deploy"
    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      configuration = {
        ApplicationName     = aws_codedeploy_app.main.name
        DeploymentGroupName = aws_codedeploy_deployment_group.bg.deployment_group_name
      }
      input_artifacts = [
        "SourceArtifact"
      ]
      provider  = "CodeDeploy"
      version   = "1"
      run_order = 1
    }
  }
}
