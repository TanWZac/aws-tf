# AWS Terraform Template (Production-Ready Platform + AI)

This repository is a reusable Terraform baseline for:

- Platform infrastructure (networking, shared security, logging, storage)
- AI infrastructure (SageMaker-ready IAM, private notebook option, model image registry, dataset storage)
- Request-serving infrastructure (ALB + ECS Fargate autoscaling)

It is structured for multi-environment deployments and team collaboration.

## Production-Grade Features

- Environment overlays: `environments/dev`, `environments/stage`, `environments/prod`
- Remote state ready: S3 backend + DynamoDB lock table configuration files
- Guardrails: optional `allowed_account_ids` provider enforcement
- Standardized tagging via provider `default_tags` + `additional_tags`
- High-availability networking: NAT mode (`single` or `per_az`) and private VPC endpoints
- Elastic request handling: ALB + ECS service + CPU/memory target-tracking autoscaling
- CI checks for fmt/validate/plan on each environment
- Module scaffold script for fast and consistent module creation

## Repository Layout

- `main.tf`, `variables.tf`, `outputs.tf`: root stack composition
- `providers.tf`, `versions.tf`: provider/version/backend definitions
- `modules/platform`: shared platform resources
- `modules/ai`: AI resources
- `modules/service`: autoscaling application service resources
- `modules/_template`: scaffold template for new modules
- `environments/<env>/terraform.tfvars`: environment-specific values
- `environments/<env>/backend.hcl.example`: backend config template per environment
- `scripts/new-module.sh`: module scaffolder
- `docs/adding-modules.md`: module extension workflow
- `.github/workflows/terraform-ci.yml`: CI validation and planning
- `Makefile`: standardized local commands

## What Gets Deployed

Platform module:

- VPC, public/private subnets, IGW
- NAT gateway strategies: `none`, `single`, `per_az`
- Routing and subnet associations per private subnet
- VPC endpoints for S3, ECR API, ECR DKR, and CloudWatch Logs
- Workload security group
- CloudWatch log group
- Encrypted, versioned, blocked-public-access S3 bucket

AI module:

- Encrypted, versioned, blocked-public-access S3 dataset bucket
- SageMaker execution role and S3 access policy
- Optional private SageMaker notebook instance
- ECR repository for model-serving images
- CloudWatch log group

Service module:

- Internet-facing ALB in public subnets
- Optional HTTPS listener with HTTP->HTTPS redirect
- Optional WAF web ACL with managed common rules and IP rate-limiting
- ALB access logs to S3 and optional WAF logs to Firehose/S3
- ECS Fargate service in private subnets
- Auto scaling target/policies for CPU and memory
- Optional request-count autoscaling based on ALB traffic per target
- ECS deployment circuit breaker with rollback controls
- CloudWatch logs for service containers
- Security group segmentation between ALB and tasks

## First-Time Setup

1. Create backend config files from examples:
   - Copy `environments/dev/backend.hcl.example` to `environments/dev/backend.hcl`
   - Copy `environments/stage/backend.hcl.example` to `environments/stage/backend.hcl`
   - Copy `environments/prod/backend.hcl.example` to `environments/prod/backend.hcl`
2. Replace placeholder values for:
   - S3 state bucket name
   - DynamoDB lock table name
3. Ensure AWS credentials are configured.

## Deployment Commands

Dev:

- `make init ENV=dev`
- `make fmt`
- `make validate`
- `make plan ENV=dev`
- `make apply ENV=dev`

Stage and prod use the same commands with `ENV=stage` or `ENV=prod`.

## Scale Tuning

For startup growth and burst traffic, adjust these variables per environment:

- `nat_gateway_mode`: use `per_az` for production high availability
- `app_desired_count`, `app_min_capacity`, `app_max_capacity`: baseline and max concurrency
- `app_task_cpu`, `app_task_memory`: per-task capacity profile
- `enable_vpc_endpoints`: keep enabled to reduce NAT dependency for AWS service traffic
- `availability_zones`: add zones as you scale across more AZs
- `enable_alb_https`, `alb_certificate_arn`, `alb_ssl_policy`: enforce TLS at the edge
- `enable_waf`, `waf_rate_limit`: baseline L7 protection and abuse throttling
- `enable_alb_deletion_protection`: keep true for stage/prod
- `enable_alb_access_logs`, `enable_waf_logging`, `edge_logs_prefix`: improve incident forensics
- `enable_request_count_autoscaling`, `request_count_target`: scale on real traffic instead of only host utilization
- `enable_deployment_circuit_breaker`, `deployment_rollback_on_failure`: safer zero-downtime deployments

## Security Notes

- Stage and prod tfvars include placeholder ACM certificate ARNs. Replace these values before `terraform apply`.
- Keep Git SSL verification enabled unless temporarily required by your enterprise proxy setup.

## Branch Strategy

Use resource- or feature-scoped branches and merge through PRs:

- `feature/platform-<resource>`
- `feature/ai-<resource>`
- `feature/module-<name>`
- `fix/<issue>`

Recommended flow:

1. Branch from `main`.
2. Add or update module(s).
3. Run `make fmt validate plan ENV=<env>`.
4. Open PR and rely on CI as merge gate.

## Adding New Modules Quickly

1. Run `./scripts/new-module.sh <module_name>`.
2. Implement resources in `modules/<module_name>/main.tf`.
3. Define module interface in `variables.tf` and `outputs.tf`.
4. Wire module call in root `main.tf`.
5. Add any new root variables and outputs.

Detailed workflow is available in `docs/adding-modules.md`.

## Notes

- Terraform CLI must be installed locally (>= 1.6).
- `terraform.tfvars` is intentionally ignored; use environment-specific tfvars files.
- NAT gateway and SageMaker instances incur cost; tune per environment.
