locals {
  sg_alb_name = "sample-apache-alb-sg"
  sg_ec2_name = "sample-apache-ec2-sg"
  alb_name = "sample-apache-alb"
  tg_name = "sample-apache-tg"
  launch_template_name = "sample-apache-template"
  auto_scaling_name = "sample-apache-auto-scaling-group"
  key_name = "sample-apache-ec2-keypair"
  iam_role_name = "ApacheAlbEC2IAMRole"
  image_id = "ami-0947c48ae0aaf6781"
  instance_type = "t2.micro"
}