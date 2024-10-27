locals {
  ecs_task_definition_name            = "sample-ecs-task"
  ecs_cluster_name                    = "sample-ecs-cluster"
  ecs_service_name                    = "sample-ecs-service"
  ecs_capacity_provider_name          = "sample-capacity-provider"
  ecs_security_group_name             = "sample-ecs-security-group"
  autoscaling_group_name              = "sample-asg-ecs-cluster"
  launch_template_name                = "sample-launch-template"
  lb_name                             = "sample-lb"
  lb_target_group_name                = "sample-lb-target-group"
  lb_target_group_sub_name            = "sample-lb-target-group-sub"
  lb_security_group_name              = "sample-lb-security-group"
  task_execution_iam_role_name        = "SampleEcsTaskExecutionRole"
  task_iam_role_name                  = "SampleEcsTaskRole"
  task_role_policy_name               = "sample-task-role-policy"
  s3_name                             = "sample-ecs-s3"
  codedeploy_app_name                 = "sample-code-deploy-app"
  codedeploy_deployment_group_bg_name = "sample-code-deploy-app-group-bg"
  codepipeline_iam_role_name          = "CodePipelineServiceRole"
  codepipeline_name                   = "sample-code-pipeline"
}