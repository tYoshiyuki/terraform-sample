locals {
  ecs_task_definition_name     = "sample-ecs-task"
  ecs_cluster_name             = "sample-ecs-cluster"
  ecs_service_name             = "sample-ecs-service"
  ecs_security_group_name      = "sample-ecs-security-group"
  lb_name                      = "sample-lb"
  lb_target_group_name         = "sample-lb-target-group"
  lb_security_group_name       = "sample-lb-security-group"
  task_execution_iam_role_name = "SampleEcsTaskExecutionRole"
  task_iam_role_name           = "SampleEcsTaskRole"
  task_role_policy_name        = "sample-task-role-policy"
}
