locals {
  sg_alb_name          = "sample-nginx-alb-sg"
  sg_ec2_name          = "sample-nginx-ec2-sg"
  alb_name             = "sample-nginx-alb"
  tg_name              = "sample-nginx-tg"
  launch_template_name = "sample-nginx-template"
  auto_scaling_name    = "sample-nginx-auto-scaling-group"
  key_name             = "sample-nginx-ec2-keypair"
  iam_role_name        = "NginxAlbEC2IAMRole"
  image_id             = "ami-0947c48ae0aaf6781"
  instance_type        = "t2.micro"
}