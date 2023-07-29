resource "aws_iam_role" "iam" {
  path = "/"
  name = local.iam_role
  assume_role_policy = file("./iam_policy.json")
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