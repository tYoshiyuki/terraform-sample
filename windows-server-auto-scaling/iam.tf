resource "aws_iam_role" "iam" {
  path = "/"
  name = var.iam_role
  assume_role_policy = jsonencode({
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{
        "Service":"ec2.amazonaws.com"
      },
      "Action":"sts:AssumeRole"
    }]
  })
  max_session_duration = 3600
  tags = {}
}

resource "aws_iam_instance_profile" "iam" {
  path = "/"
  name = aws_iam_role.iam.name
  role = aws_iam_role.iam.name
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "iam" {
  role = aws_iam_role.iam.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}