################################################################################
# Common
################################################################################
resource "aws_iam_role" "main" {
  path                 = "/"
  name                 = "SampleEcsTaskExecutionRole"
  assume_role_policy   = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  max_session_duration = 3600
  tags                 = {}
}

resource "aws_iam_role_policy" "main" {
  role = aws_iam_role.main.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_autoscaling_group" "main" {
  name = local.autoscaling_group_name
  launch_template {
    id      = aws_launch_template.main.id
    version = "1"
  }
  min_size                  = 0
  max_size                  = 1
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

################################################################################
# ECR
################################################################################
resource "aws_ecr_repository" "main" {
  name         = local.ecr_repository_name
  force_delete = true
}

# Dockerイメージの初期データを投入
resource "null_resource" "docker_image" {
  triggers = {
    file_content_md5 = md5(file("${path.module}/dockerbuild.sh"))
  }

  provisioner "local-exec" {
    command = "sh ${path.module}/dockerbuild.sh"

    environment = {
      AWS_REGION     = "ap-northeast-1"
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
      REPO_URL       = aws_ecr_repository.main.repository_url
      CONTAINER_NAME = aws_ecr_repository.main.name
    }
  }
}

################################################################################
# ECS Fargate
################################################################################
resource "aws_ecs_cluster" "fargate" {
  name = local.ecs_cluster_fargate_name
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.fargate.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "fargate" {
  container_definitions = templatefile("./container_definitions_fargate.json", {
    image_rul          = aws_ecr_repository.main.repository_url
    awslogs_group_name = local.ecs_task_definition_fargate_name
  })
  family             = local.ecs_task_definition_fargate_name
  execution_role_arn = aws_iam_role.main.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  cpu    = "1024"
  memory = "3072"
}

################################################################################
# ECS EC2
################################################################################
resource "aws_ecs_cluster" "ec2" {
  name = local.ecs_cluster_ec2_name
}

resource "aws_ecs_capacity_provider" "main" {
  name = local.ecs_capacity_provider_ec2_name

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

resource "aws_ecs_cluster_capacity_providers" "ec2" {
  cluster_name = aws_ecs_cluster.ec2.name

  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

resource "aws_ecs_task_definition" "ec2" {
  container_definitions = templatefile("./container_definitions_ec2.json", {
    image_rul          = aws_ecr_repository.main.repository_url
    awslogs_group_name = local.ecs_task_definition_ec2_name
  })
  family             = local.ecs_task_definition_ec2_name
  execution_role_arn = aws_iam_role.main.arn
  network_mode       = "bridge"
  requires_compatibilities = [
    "EC2"
  ]
  cpu    = "2048"
  memory = "3072"
}

resource "aws_launch_template" "main" {
  name = "NewECSLaunchTemplate"
  user_data = base64encode(templatefile("./user_data.sh", {
    cluster_name = aws_ecs_cluster.ec2.name
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
  image_id      = "ami-0eed46c7eaecb7b58"
  instance_type = "t3.medium"
}

resource "aws_security_group" "main" {
  description = local.security_group_name
  name        = local.security_group_name
  tags = {
    Name = "all-allow"
  }
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
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
