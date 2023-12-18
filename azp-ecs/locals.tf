locals {
  ecr_repository_name              = "sample-azp-agent"
  ecs_cluster_fargate_name         = "sample-azp-cluster-fargate"
  ecs_task_definition_fargate_name = "sample-azp-agent-fargate"
  ecs_cluster_ec2_name             = "sample-azp-cluster-ec2"
  ecs_task_definition_ec2_name     = "sample-azp-agent-ec2"
  ecs_capacity_provider_ec2_name   = "sample-capacity-provider"
  autoscaling_group_name           = "sample-asg-azp-cluster-ec2"
  security_group_name              = "sample-azp-ecs-sg"
}
