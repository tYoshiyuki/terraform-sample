<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.67.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.1 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.9.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app-runner"></a> [app-runner](#module\_app-runner) | terraform-aws-modules/app-runner/aws | 1.2.0 |
| <a name="module_security-group"></a> [security-group](#module\_security-group) | terraform-aws-modules/security-group/aws | 5.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ecr_repository.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_role.iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_vpc_endpoint.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [null_resource.docker_image](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait_10_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.AWSAppRunnerServicePolicyForECRAccess](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_scaling_configurations"></a> [auto\_scaling\_configurations](#input\_auto\_scaling\_configurations) | Map of auto-scaling configuration definitions to create | `any` | `{}` | no |
| <a name="input_enable_observability_configuration"></a> [enable\_observability\_configuration](#input\_enable\_observability\_configuration) | Determines whether an X-Ray Observability Configuration will be created and assigned to the service | `bool` | `false` | no |
| <a name="input_private_ecr_arn"></a> [private\_ecr\_arn](#input\_private\_ecr\_arn) | The ARN of the private ECR repository that contains the service image to launch | `string` | `null` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the service | `string` | `"sample-app-runner"` | no |
| <a name="input_source_configuration"></a> [source\_configuration](#input\_source\_configuration) | The source configuration for the service | `any` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | vpc id. | `any` | n/a | yes |
| <a name="input_vpc_subnet1"></a> [vpc\_subnet1](#input\_vpc\_subnet1) | vpc subnet1. | `any` | n/a | yes |
| <a name="input_vpc_subnet2"></a> [vpc\_subnet2](#input\_vpc\_subnet2) | vpc subnet2. | `any` | n/a | yes |
| <a name="input_vpc_subnet3"></a> [vpc\_subnet3](#input\_vpc\_subnet3) | vpc subnet3. | `any` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->