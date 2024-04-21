data "aws_caller_identity" "current" {}

module "app-runner" {
  source       = "terraform-aws-modules/app-runner/aws"
  version      = "1.2.0"
  service_name = var.service_name

  create_ingress_vpc_connection = true
  ingress_vpc_id                = var.vpc_id
  ingress_vpc_endpoint_id       = aws_vpc_endpoint.main.id

  auto_scaling_configurations = var.auto_scaling_configurations

  network_configuration = {
    ingress_configuration = {
      is_publicly_accessible = false
    }
    egress_configuration = {
      egress_type = "DEFAULT"
    }
  }

  enable_observability_configuration = var.enable_observability_configuration

  source_configuration = {
    authentication_configuration = {
      access_role_arn = time_sleep.wait_10_seconds.triggers["iam_arn"]
    }
    auto_deployments_enabled = true
    image_repository = {
      image_configuration = {
        port = 80
      }
      image_identifier      = "${aws_ecr_repository.main.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }
}

# ロール生成時エラー防止のためスリープ処理を追加
# https://dev.classmethod.jp/articles/terraform-app_runner-build-error/
resource "time_sleep" "wait_10_seconds" {
  create_duration = "10s"

  triggers = {
    iam_arn = aws_iam_role.main.arn
  }
}

module "security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  ingress_with_cidr_blocks = concat([{
    rule        = "http-80-tcp"
    cidr_blocks = "0.0.0.0/0"
  }])
  name = "sample-app-runner-sg"
}

resource "aws_vpc_endpoint" "main" {
  vpc_id            = var.vpc_id
  subnet_ids        = [var.vpc_subnet1, var.vpc_subnet2, var.vpc_subnet3]
  service_name      = "com.amazonaws.ap-northeast-1.apprunner.requests"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    module.security-group.security_group_id,
  ]
}

resource "aws_ecr_repository" "main" {
  name                 = var.service_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
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
