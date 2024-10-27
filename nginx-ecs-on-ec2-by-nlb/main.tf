# -------------------------------------------------------------------
# ECS
# -------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = local.ecs_cluster_name
}

resource "aws_ecs_service" "main" {
  name                               = local.ecs_service_name
  cluster                            = aws_ecs_cluster.main.arn
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  propagate_tags                     = "SERVICE"
  enable_execute_command             = true
  desired_count                      = "1"
  task_definition                    = aws_ecs_task_definition.main.arn

  health_check_grace_period_seconds = 60

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = "80"
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count, capacity_provider_strategy, load_balancer]
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = local.ecs_task_definition_name
  requires_compatibilities = ["EC2"]
  cpu                      = "2048"
  memory                   = "3072"
  network_mode             = "bridge"
  container_definitions    = file("./container_definitions.json")
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
}

resource "aws_ecs_capacity_provider" "main" {
  name = local.ecs_capacity_provider_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.main.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 10000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

resource "aws_autoscaling_group" "main" {
  name = local.autoscaling_group_name
  launch_template {
    id      = aws_launch_template.main.id
    version = "1"
  }
  min_size                  = 0
  max_size                  = 5
  desired_capacity          = 0
  default_cooldown          = 300
  health_check_type         = "EC2"
  health_check_grace_period = 0
  vpc_zone_identifier = [
    var.vpc_subnet1,
    var.vpc_subnet2,
    var.vpc_subnet3
  ]
  termination_policies = [
    "Default"
  ]
  service_linked_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = local.autoscaling_group_name
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "main" {
  name = local.launch_template_name
  user_data = base64encode(templatefile("./user_data.sh", {
    cluster_name = aws_ecs_cluster.main.name
  }))
  iam_instance_profile {
    arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/ecsInstanceRole"
  }
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    device_index                = 0
    security_groups = [
      aws_security_group.main.id
    ]
  }
  image_id      = data.aws_ssm_parameter.ecs_ami_id.value
  instance_type = "t3.medium"
}

resource "aws_security_group" "main" {
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

resource "aws_iam_role" "task_execution_role" {
  name = local.task_execution_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
}

resource "aws_iam_role" "task_role" {
  name = local.task_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "task_role_policy" {
  name   = local.task_role_policy_name
  policy = file("./task_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}

# -------------------------------------------------------------------
# Code Pipeline, Code Deploy
# -------------------------------------------------------------------
resource "aws_codedeploy_app" "main" {
  name             = local.codedeploy_app_name
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "bg" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = local.codedeploy_deployment_group_bg_name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CodeDeployRole"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.main.name
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.main.arn]
      }

      target_group {
        name = aws_lb_target_group.main.name
      }

      target_group {
        name = aws_lb_target_group.sub.name
      }
    }
  }
}

data "archive_file" "config" {
  type        = "zip"
  output_path = "config.zip"

  source {
    filename = "task_definition.json"
    content = templatefile("./task_definition.json", {
      task_role           = "${aws_iam_role.task_role.arn}"
      task_execution_role = "${aws_iam_role.task_execution_role.arn}"
    })
  }

  source {
    filename = "appspec.yaml"
    content  = file("./appspec.yaml")
  }

  depends_on = [aws_iam_policy.task_role_policy, aws_iam_role.task_execution_role]
}

resource "aws_s3_bucket" "main" {
  bucket        = local.s3_name
  force_destroy = true
}

resource "aws_s3_object" "main" {
  bucket     = aws_s3_bucket.main.id
  key        = "config.zip"
  source     = "config.zip"
  depends_on = [data.archive_file.config]
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
        S3ObjectKey          = "config.zip"
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
        ApplicationName                = aws_codedeploy_app.main.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.bg.deployment_group_name
        TaskDefinitionTemplateArtifact = "SourceArtifact"
        TaskDefinitionTemplatePath     = "task_definition.json"
        AppSpecTemplateArtifact        = "SourceArtifact"
        AppSpecTemplatePath            = "appspec.yaml"
      }
      input_artifacts = [
        "SourceArtifact"
      ]
      provider  = "CodeDeployToECS"
      version   = "1"
      run_order = 1
    }
  }
}

resource "aws_iam_role" "iam_codepipeline" {
  name = local.codepipeline_iam_role_name
  path = "/service-role/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "codepipeline.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codepipeline_policy" {
  name   = aws_iam_role.iam_codepipeline.name
  path   = "/service-role/"
  policy = file("./codepipeline_policy.json")
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.iam_codepipeline.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}
