# terraform-sample
Terraform のサンプル。

## Note
- Terraform

### apache-alb-auto-scaling
- Amazon Linux 2023 + ALB + オートスケーリンググループ のサンプル
    - オートスケーリンググループは、プロダクション・カナリアの複数構成
    - CodePipeLine、CodeDeployによるブルー・グリーンデプロイ構成

### azp-ecs
- Azure DevOps PipeLine Agent と ECS (ECS on Fargate・ECS on EC2) のサンプル
    - `terraform apply` 時に `docker build` を実施するため、実行時には Docker が必要

### mailhog-ecs
- ECS (Fargate) + MailHog のサンプル

### nginx-alb-auto-scaling
- Amazon Linux 2023 + ALB + オートスケーリンググループ のサンプル
    - オートスケーリンググループは、プロダクション・カナリアの複数構成

### nginx-apprunner
- App Runner のサンプル

### nginx-ecs
- ECS (Fargate) のサンプル

### windows-server-auto-scaling
- Windows Server + オートスケーリンググループ のサンプル