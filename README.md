# AWS Terraform Template (Production-Ready Platform + AI)

This repository is a reusable Terraform baseline for:

- Platform infrastructure (networking, shared security, logging, storage)
- AI infrastructure (SageMaker-ready IAM, private notebook option, model image registry, dataset storage)
- Request-serving infrastructure (ALB + ECS Fargate autoscaling)

It is structured for multi-environment deployments and team collaboration.

## Production-Grade Features

- Environment overlays: `environments/dev`, `environments/stage`, `environments/prod`
- Remote runs/state through HCP Terraform (`tanwzac-org/aws-tf`)
- Guardrails: optional `allowed_account_ids` provider enforcement
- Standardized tagging via provider `default_tags` + `additional_tags`
- High-availability networking: NAT mode (`single` or `per_az`) and private VPC endpoints
- Elastic request handling: ALB + ECS service + CPU/memory target-tracking autoscaling
- CI checks for fmt/validate/plan on each environment
- CI quality gates for linting and IaC security scanning
- Module scaffold script for fast and consistent module creation

## Repository Layout

- `main.tf`, `variables.tf`, `outputs.tf`: root stack composition
- `providers.tf`, `versions.tf`: provider/version/HCP Terraform workspace definitions
- `accounts.tf`: registry of AWS account IDs per OU — generated from `org/`, see below
- `modules/platform`: shared platform resources
- `modules/ai`: AI resources
- `modules/service`: autoscaling application service resources
- `modules/_template`: scaffold template for new modules
- `environments/<env>/terraform.tfvars`: environment-specific values
- `bootstrap/`: optional legacy helper for self-managed S3 state; root deployments use HCP Terraform
- `org/`: creates the AWS Organization, OUs, and member accounts, run once (or
  whenever account structure changes) — see `org/README.md`
- `scripts/new-module.sh`: module scaffolder
- `docs/adding-modules.md`: module extension workflow
- `.github/workflows/terraform-ci.yml`: CI validation and planning
- `Makefile`: standardized local commands, including `org-init`/`org-plan`/`org-apply`/`org-sync-accounts`

## Org & Account Setup (new repos / new accounts)

Before `bootstrap/` and before any `ENV=` deploy, if you don't already have
your AWS accounts created:

```bash
cd org
cp terraform.tfvars.example terraform.tfvars   # fill in account emails etc.
terraform init
terraform apply
cd ..
make org-sync-accounts   # writes real account IDs into accounts.tf
```

See `org/README.md` for what this creates (Organization, OUs, prod/dev/stage
accounts, baseline SCPs, org-wide CloudTrail, budget alert) and what still
has to be done manually (root MFA, IAM Identity Center first-time enable).

If your accounts already exist, skip `org/` and just fill in the real IDs
in `accounts.tf` by hand.

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
- Edge log lifecycle retention controls and optional customer-managed KMS encryption
- ECS Fargate service in private subnets
- Auto scaling target/policies for CPU and memory
- Optional request-count autoscaling based on ALB traffic per target
- ECS deployment circuit breaker with rollback controls
- CloudWatch logs for service containers
- Security group segmentation between ALB and tasks

## First-Time Setup

1. Log in to HCP Terraform locally:

   ```bash
   terraform login
   ```

2. Confirm you can access the HCP Terraform workspace:

   - Organization: `tanwzac-org`
   - Workspace: `aws-tf`
   - Workspace ID: `ws-YkExzMvB4gwqvpYN`

3. Ensure AWS credentials/variables are configured for the HCP Terraform workspace.
   For remote runs, prefer workspace variables or variable sets for AWS auth.

4. Create local `environments/<env>/terraform.tfvars` files when using CLI-driven
   plans from your machine. Do not commit real tfvars.

## Deployment Commands

Dev:

- `make init ENV=dev`
- `make fmt`
- `make validate`
- `make plan ENV=dev`
- `make apply ENV=dev`

Stage and prod use the same commands with `ENV=stage` or `ENV=prod`.

Quality gates:

- `make lint`
- `make security-check`

Load testing:

- `BASE_URL=https://<alb-or-domain> make loadtest-smoke`
- `BASE_URL=https://<alb-or-domain> make loadtest-spike`

Detailed rollout guidance is in `docs/deployment-runbook.md`.

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
- `edge_logs_retention_days`: control edge-log retention cost and compliance window
- `enable_edge_logs_kms_encryption`, `create_edge_logs_kms_key`, `edge_logs_kms_key_arn`: enforce customer-managed encryption
- `enable_request_count_autoscaling`, `request_count_target`: scale on real traffic instead of only host utilization
- `enable_deployment_circuit_breaker`, `deployment_rollback_on_failure`: safer zero-downtime deployments

## Security Notes

- Stage and prod tfvars include placeholder ACM certificate ARNs. Replace these values before `terraform apply`.
- Environment baseline examples are available at `environments/<env>/terraform.tfvars.example`.
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

- Terraform CLI must be installed locally (>= 1.9).
- `terraform.tfvars` is intentionally ignored; use environment-specific tfvars files.
- NAT gateway and SageMaker instances incur cost; tune per environment.
