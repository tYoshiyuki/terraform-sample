<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.38.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | 2.4.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.38.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.4.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.canary](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_group.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/autoscaling_group) | resource |
| [aws_codedeploy_app.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/codedeploy_app) | resource |
| [aws_codedeploy_deployment_group.bg](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/codedeploy_deployment_group) | resource |
| [aws_codedeploy_deployment_group.in_place](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/codedeploy_deployment_group) | resource |
| [aws_codepipeline.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/codepipeline) | resource |
| [aws_iam_instance_profile.iam](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.IAMManagedPolicy](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/iam_policy) | resource |
| [aws_iam_role.iam](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/iam_role) | resource |
| [aws_iam_role.iam_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.role-policy-attachment](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/key_pair) | resource |
| [aws_launch_template.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/launch_template) | resource |
| [aws_lb.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/lb) | resource |
| [aws_lb_listener.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.canary](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/lb_target_group) | resource |
| [aws_s3_bucket.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_versioning.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.main](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/s3_object) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/security_group) | resource |
| [aws_security_group.ec2](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/resources/security_group) | resource |
| [local_sensitive_file.keypair_pem](https://registry.terraform.io/providers/hashicorp/local/2.4.1/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.keypair_pub](https://registry.terraform.io/providers/hashicorp/local/2.4.1/docs/resources/sensitive_file) | resource |
| [tls_private_key.main](https://registry.terraform.io/providers/hashicorp/tls/4.0.5/docs/resources/private_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.AmazonS3FullAccess](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.AmazonSSMManagedInstanceCore](https://registry.terraform.io/providers/hashicorp/aws/5.38.0/docs/data-sources/iam_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | vpc id. | `string` | n/a | yes |
| <a name="input_vpc_subnet1"></a> [vpc\_subnet1](#input\_vpc\_subnet1) | vpc subnet1. | `string` | n/a | yes |
| <a name="input_vpc_subnet2"></a> [vpc\_subnet2](#input\_vpc\_subnet2) | vpc subnet2. | `string` | n/a | yes |
| <a name="input_vpc_subnet3"></a> [vpc\_subnet3](#input\_vpc\_subnet3) | vpc subnet3. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->