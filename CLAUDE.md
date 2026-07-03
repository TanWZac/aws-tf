# Terraform 平台仓库 — Claude 指南

## 模块结构
- `modules/platform/` — VPC、子网、NAT、VPC 端点、S3
- `modules/service/` — ALB、ECS Fargate、WAF、自动扩缩容、CloudWatch 告警
- `modules/ai/` — SageMaker、ECR、AI 数据集 S3
- `modules/api_gateway/` — HTTP API Gateway、JWT 授权器、限流
- `modules/redis/` — ElastiCache Redis（可选，`enable_redis = true`）
- `bootstrap/` — 初始化状态后端（S3 桶 + DynamoDB 锁表），仅运行一次

## 关键约束
- `checks.tf` — 生产保护检查（WAF、HTTPS、NAT per_az、最少 2 个任务）
- `variables.tf` — 根级变量，含 Fargate CPU/内存枚举验证
- `modules/service/variables.tf` — 含容量关系前置条件
- 修改变量后必须同步更新 `environments/*/terraform.tfvars.example`

## 环境管理
```bash
terraform init -backend-config=environments/dev/backend.hcl
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

## Fargate CPU/内存有效组合
CPU: 256 | 512 | 1024 | 2048 | 4096 | 8192 | 16384
内存须为 512 的倍数，且与 CPU 相兼容

## 新增资源规则
1. 检查 `checks.tf` 是否需要新的生产保护
2. 将输出写入 SSM，并更新 `aws-platform/contracts/ssm-parameters.yaml`
3. 新变量须加入所有 `environments/*/terraform.tfvars.example`
4. Redis 等可选模块须有 `count = var.enable_X ? 1 : 0` 开关

## 禁止
- 禁止修改 `bootstrap/` 的 `prevent_destroy` 生命周期
- 禁止在 tfvars 文件中硬编码 AWS 账户 ID
- 禁止绕过 `checks.tf` 的断言
