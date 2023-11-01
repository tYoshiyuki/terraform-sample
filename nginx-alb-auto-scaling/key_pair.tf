resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = local.key_name
  public_key = tls_private_key.private_key.public_key_openssh

  tags = {
    Name = local.key_name
  }
}

resource "local_sensitive_file" "keypair_pem" {
  filename = "${path.module}/keypair.pem"
  content  = tls_private_key.private_key.private_key_pem
}

resource "local_sensitive_file" "keypair_pub" {
  filename = "${path.module}/keypair.pub"
  content  = tls_private_key.private_key.public_key_openssh
}