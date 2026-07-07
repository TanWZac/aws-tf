# Getting Started

This guide walks you through deploying this repo from scratch. No deep Terraform knowledge required — follow the steps in order.

---

## What this repo deploys

```
AWS Account
└── VPC  (networking: subnets, NAT, VPC endpoints)
    ├── ECS Fargate service  (your container app behind an ALB)
    ├── SageMaker notebook   (optional AI workspace)
    ├── ECR repository       (container image registry)
    ├── S3 buckets           (platform storage, AI datasets, access logs)
    └── API Gateway          (optional HTTP API in front of the ALB)
```

Three separate environments are supported: **dev**, **stage**, **prod**. Each deploys into its own AWS account (or the same account if preferred).

---

## Prerequisites

Install these tools once on your machine:

| Tool | Purpose | Install |
|---|---|---|
| Terraform ≥ 1.6 | Runs the infrastructure code | https://developer.hashicorp.com/terraform/install |
| AWS CLI v2 | Authenticates to AWS | https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html |
| make | Runs the repo's shortcut commands | pre-installed on macOS/Linux |
| tflint | Lints Terraform code | `brew install tflint` or https://github.com/terraform-linters/tflint |
| pre-commit (optional) | Runs checks before each git commit | `pip install pre-commit` then `pre-commit install` |

---

## Step 1 — Register your AWS accounts

Open **`accounts.tf`** in the repo root and replace the placeholder values with your real AWS account IDs.

```hcl
# accounts.tf
ou_production = {
  account_a = {
    id     = "111111111111"   # ← your real 12-digit account ID
    name   = "prod-primary"
    region = "us-east-1"
  }
}
ou_development = {
  account_c = {
    id     = "333333333333"   # ← your real 12-digit account ID
    name   = "dev"
    region = "us-east-1"
  }
}
```

**How to find your account ID:** In the AWS Console, click your username in the top-right corner — the 12-digit number shown is your account ID.

Once filled in, Terraform will automatically refuse to run against the wrong account.

---

## Step 2 — Log in to HCP Terraform

The root stack stores state and creates runs in HCP Terraform:

- Organization: `tanwzac-org`
- Workspace: `aws-tf`
- Workspace ID: `ws-YkExzMvB4gwqvpYN`

Log in before running CLI-driven plans locally:

```bash
terraform login
```

AWS credentials should be configured in the HCP Terraform workspace using
workspace variables or variable sets. Do not commit AWS credentials or real
secret tfvars to the repo.

---

## Step 3 — Initialize the HCP Terraform workspace

The backend is configured in root `versions.tf`; do not pass
`-backend-config=environments/<env>/backend.hcl` for normal root deployments.

```bash
make init
```

`bootstrap/` remains only as an optional helper if you deliberately choose a
self-managed S3 backend in a different fork.

---

## Step 4 — Review environment variables

Each environment has a `terraform.tfvars` file with its settings.

```
environments/
  dev/terraform.tfvars    ← dev settings (already checked in, safe to edit)
  stage/terraform.tfvars  ← stage settings
  prod/terraform.tfvars   ← prod settings
```

The key settings to check per environment:

| Setting | dev | stage | prod |
|---|---|---|---|
| `nat_gateway_mode` | `single` (cheaper) | `per_az` | `per_az` |
| `enable_alb_https` | `false` | `true` | `true` |
| `alb_certificate_arn` | `null` | `"arn:aws:acm:..."` | `"arn:aws:acm:..."` |
| `enable_waf` | `false` | `true` | `true` |
| `enable_alb_deletion_protection` | `false` | `true` | `true` |
| `create_sagemaker_notebook` | `false` | `true` | `true` |

For stage and prod, replace `alb_certificate_arn` with a real ACM certificate ARN from your AWS account.

---

## Step 5 — Authenticate to AWS

```bash
# Option A: named profile (local development)
export AWS_PROFILE=my-dev-profile

# Option B: environment variables (CI or temporary credentials)
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...   # if using temporary credentials / SSO
```

To verify you are authenticated to the right account:
```bash
aws sts get-caller-identity
```
The `Account` field in the output must match the account ID you put in `accounts.tf` for the environment you are about to deploy.

---

## Step 6 — Deploy

Use `make` to run Terraform. The `ENV` variable selects which environment to deploy.

```bash
# 1. Format check (catches whitespace/style issues)
make fmt

# 2. Download providers and connect to the HCP Terraform workspace
make init ENV=dev

# 3. Validate the configuration (catches typos and type errors)
make validate

# 4. Preview what will be created/changed/destroyed — SAFE, nothing is deployed yet
make plan ENV=dev

# 5. Apply the plan (actually deploys)
make apply ENV=dev
```

Repeat with `ENV=stage` and `ENV=prod` once dev is confirmed working.

---

## Common operations

### Change a setting (e.g. scale up ECS tasks)

1. Edit the relevant value in `environments/<env>/terraform.tfvars`
2. Run `make plan ENV=<env>` and review the diff
3. Run `make apply ENV=<env>` to apply

### Add a new module

```bash
./scripts/new-module.sh my-module-name
```

This creates `modules/my-module-name/` with the standard scaffold. See [docs/adding-modules.md](adding-modules.md) for the full workflow.

### Run load tests after deploy

```bash
# Get the ALB DNS from Terraform output
make plan ENV=dev   # outputs are shown at the bottom

# Smoke test (5 users, 2 minutes)
make loadtest-smoke BASE_URL=https://your-alb-dns.elb.amazonaws.com

# Spike test (ramps to 200 users)
make loadtest-spike BASE_URL=https://your-alb-dns.elb.amazonaws.com
```

### Destroy an environment

```bash
# CONFIRM=yes is required as a safety guard
make destroy ENV=dev CONFIRM=yes
```

> Never run `make destroy ENV=prod` unless you are certain. Deletion protection is enabled on the ALB for stage/prod.

---

## Understanding the key files

```
accounts.tf                 ← YOUR AWS account IDs live here (fill in once)
main.tf                     ← wires modules together (the "table of contents")
variables.tf                ← all configurable settings and their defaults
outputs.tf                  ← values printed after apply (ALB URL, cluster name, etc.)
providers.tf                ← AWS provider config (region, account guardrail)
versions.tf                 ← Terraform and provider version pins

modules/
  platform/                 ← VPC, subnets, NAT, VPC endpoints, base S3
  ai/                       ← SageMaker IAM, notebook, ECR, dataset S3
  service/                  ← ALB, ECS Fargate, WAF, autoscaling, logging
  api_gateway/              ← HTTP API Gateway in front of the ALB (optional)

environments/
  dev/terraform.tfvars      ← dev-specific values
  stage/terraform.tfvars    ← stage-specific values
  prod/terraform.tfvars     ← prod-specific values
```

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `Error: No valid credential sources found` | Not authenticated to AWS | Run `aws configure` or set `AWS_PROFILE` |
| `Error: Account ID ... is not allowed` | Wrong AWS account for this environment | Check `accounts.tf` and your current credentials |
| `Error: Required token could not be found` | Not logged in to HCP Terraform | Run `terraform login` and retry `make init` |
| `Error acquiring the state lock` | Another Terraform/HCP run is active | Wait for the active run to finish, cancel it in HCP Terraform, or unlock from the workspace UI |
| `Error: Backend configuration changed` | HCP Terraform backend settings changed in `versions.tf` | Run `make init` again and follow Terraform's migration prompt intentionally |
| `ValidationException: image tag ... already exists` | ECR has `IMMUTABLE` tags and you pushed the same tag twice | Use a unique image tag (e.g. git SHA) for every build |

---

## Security notes

- **`env.sh`** — this file is gitignored. Never commit secrets to this file or any tracked file.
- **`accounts.tf`** — account IDs are not secret but should be reviewed when changed.
- **HCP Terraform workspace variables** — store AWS auth and sensitive runtime values there; do not commit them.
- **CI** — TFLint and Checkov run on every PR. Checkov is blocking with an explicit `.checkov.yml` baseline for existing findings.
- **Production merges** — the `.github/CODEOWNERS` file requires a review from `@senior-engineers` before any change to `environments/prod/` or `.github/` can merge.
