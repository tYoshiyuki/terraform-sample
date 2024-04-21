resource "aws_iam_role" "main" {
  path                 = "/service-role/"
  name                 = local.iam_role_name
  assume_role_policy   = file("./iam_policy.json")
  max_session_duration = 3600
  tags                 = {}
}

data "aws_iam_policy" "AWSAppRunnerServicePolicyForECRAccess" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  for_each = toset([
    data.aws_iam_policy.AWSAppRunnerServicePolicyForECRAccess.arn
  ])

  role       = aws_iam_role.main.name
  policy_arn = each.value
}
