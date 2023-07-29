locals {
  sg_name = "ec2-auto-scaling-gp-sg"
  windows_server_launch_template = "windows-server-launch-template"
  windows_server_auto_scaling = "windows-server-auto-scaling"
  key_name = "windows-server-key-pair"
  image_id = "ami-02d019195385b83ae"
  instance_type = "t2.medium"
  iam_role = "WindowsServerEC2IAMRole"
}