variable "sg_name" {
  description = "ec2 auto scaling gp sg."
}

variable "vpc_id" {
  description = "vpc id."
}

variable "windows_server_launch_template" {
  description = "windows server launch template."
}

variable "windows_server_auto_scaling" {
  description = "windows server auto scaling."
}

variable "key_name" {
  description = "key name"
}

variable "image_id" {
  description = "image id"
}

variable "instance_type" {
  description = "instance type"
}