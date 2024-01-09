data "aws_caller_identity" "current" {}

resource "aws_security_group" "security_group_alb" {
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

resource "aws_security_group" "security_group_ec2" {
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

resource "aws_autoscaling_group" "autoscaling_group" {
  name = local.auto_scaling_name
  launch_template {
    id      = aws_launch_template.launch_template.id
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
    aws_lb_target_group.lb_target_group.arn
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

resource "aws_autoscaling_group" "autoscaling_group_canary" {
  name = "${local.auto_scaling_name}-canary"
  launch_template {
    id      = aws_launch_template.launch_template.id
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
    aws_lb_target_group.lb_target_group_canary.arn
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

resource "aws_launch_template" "launch_template" {
  name      = local.launch_template_name
  user_data = filebase64("user_data.sh")
  iam_instance_profile {
    arn = aws_iam_instance_profile.iam.arn
  }
  vpc_security_group_ids = [
    aws_security_group.security_group_ec2.id
  ]
  key_name      = aws_key_pair.key_pair.key_name
  image_id      = local.image_id
  instance_type = local.instance_type
}

resource "aws_lb" "lb" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  subnets = [
    var.vpc_subnet1,
    var.vpc_subnet2,
    var.vpc_subnet3
  ]
  security_groups = [
    aws_security_group.security_group_alb.id
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

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.lb_target_group.arn
        weight = 2
      }
      target_group {
        arn    = aws_lb_target_group.lb_target_group_canary.arn
        weight = 1
      }
    }
  }
}

resource "aws_lb_target_group" "lb_target_group" {
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
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  name        = local.tg_name
}

resource "aws_lb_target_group" "lb_target_group_canary" {
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
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  name        = "${local.tg_name}-canary"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = local.s3_name
  force_destroy = true
}

resource "aws_s3_object" "s3_object" {
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "SampleApp_Linux.zip"
  source = "${path.module}/SampleApp_Linux.zip"
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership_controls" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_codedeploy_app" "code_deploy_app" {
  name             = local.code_deploy_app_name
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "codedeploy_deployment_group" {
  app_name               = aws_codedeploy_app.code_deploy_app.name
  deployment_group_name  = local.codedeploy_deployment_group_name
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CodeDeployRole"
  autoscaling_groups     = [aws_autoscaling_group.autoscaling_group.name]
  
  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.lb_target_group.name
    }
  }
}

resource "aws_codedeploy_deployment_group" "codedeploy_deployment_group_bg" {
  app_name               = aws_codedeploy_app.code_deploy_app.name
  deployment_group_name  = local.codedeploy_deployment_group_bg_name
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CodeDeployRole"
  autoscaling_groups     = [aws_autoscaling_group.autoscaling_group.name]

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
      name = aws_lb_target_group.lb_target_group.name
    }
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = local.codepipeline_name
  role_arn = aws_iam_role.iam_codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.s3_bucket.bucket
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
        S3Bucket             = aws_s3_bucket.s3_bucket.bucket
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
        ApplicationName     = aws_codedeploy_app.code_deploy_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.codedeploy_deployment_group_bg.deployment_group_name
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
