# Deployment Runbook

## 1) Prepare Environment Files

For each environment, copy examples:

- `cp environments/dev/backend.hcl.example environments/dev/backend.hcl`
- `cp environments/stage/backend.hcl.example environments/stage/backend.hcl`
- `cp environments/prod/backend.hcl.example environments/prod/backend.hcl`

Use the tracked tfvars examples as baseline and copy to your local tfvars if needed:

- `cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars`
- `cp environments/stage/terraform.tfvars.example environments/stage/terraform.tfvars`
- `cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars`

## 2) Validate and Plan

- `make fmt`
- `make validate`
- `make plan ENV=dev`
- `make plan ENV=stage`
- `make plan ENV=prod`

## 3) Apply Sequence

Recommended order:

1. `make apply ENV=dev`
2. `make apply ENV=stage`
3. `make apply ENV=prod`

## 4) Security and Network Checks

- HTTPS enabled in stage/prod with valid ACM certificate ARN
- WAF enabled in stage/prod
- ALB deletion protection enabled in stage/prod
- VPC endpoints enabled for private workloads

## 5) Autoscaling and Load Test

After deployment, run smoke and spike tests:

- `BASE_URL=https://<alb-or-domain> make loadtest-smoke`
- `BASE_URL=https://<alb-or-domain> make loadtest-spike`

Tune these variables after observing CloudWatch metrics:

- `request_count_target`
- `app_min_capacity`
- `app_max_capacity`
- `request_scale_in_cooldown`
- `request_scale_out_cooldown`
