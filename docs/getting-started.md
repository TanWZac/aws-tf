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

## Step 2 — Create the Terraform state bucket and lock table

Terraform needs a place to store its "memory" (called *state*) so it knows what it has already deployed.

For each environment, create these two AWS resources **manually** in the target account before running Terraform:

1. An **S3 bucket** to store the state file  
   Example name: `my-project-tf-state-dev`

2. A **DynamoDB table** to prevent two people running Terraform at the same time  
   Table name: anything, e.g. `my-project-tf-locks`  
   Primary key: `LockID` (type String)

---

## Step 3 — Configure the backend for each environment

Each environment has a backend config file that tells Terraform where to store its state.

```bash
cp environments/dev/backend.hcl.example   environments/dev/backend.hcl
cp environments/stage/backend.hcl.example environments/stage/backend.hcl
cp environments/prod/backend.hcl.example  environments/prod/backend.hcl
```

Open each `backend.hcl` you just created and fill in the values:

```hcl
# environments/dev/backend.hcl
bucket         = "my-project-tf-state-dev"      # ← the S3 bucket you created in Step 2
key            = "platform-ai/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "my-project-tf-locks"          # ← the DynamoDB table you created in Step 2
encrypt        = true
```

> These files are excluded from git (`.gitignore`) so your bucket names stay private.

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

# 2. Download providers and connect to the state bucket
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
  dev/backend.hcl           ← WHERE dev state is stored (you create this, not committed)
  stage/ prod/              ← same pattern
```

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `Error: No valid credential sources found` | Not authenticated to AWS | Run `aws configure` or set `AWS_PROFILE` |
| `Error: Account ID ... is not allowed` | Wrong AWS account for this environment | Check `accounts.tf` and your current credentials |
| `Error acquiring the state lock` | Another Terraform process is running | Wait, or manually release the lock in DynamoDB |
| `Error: Backend configuration changed` | `backend.hcl` was modified | Run `make init ENV=<env>` again (Terraform will prompt to migrate) |
| `ValidationException: image tag ... already exists` | ECR has `IMMUTABLE` tags and you pushed the same tag twice | Use a unique image tag (e.g. git SHA) for every build |

---

## Security notes

- **`env.sh`** — this file is gitignored. Never commit secrets to this file or any tracked file.
- **`accounts.tf`** — account IDs are not secret but should be reviewed when changed.
- **`environments/*/backend.hcl`** — gitignored. Contains bucket names; treat as internal config.
- **CI** — tfsec and Checkov run on every PR and will block merges on security findings. Review the CI output before merging.
- **Production merges** — the `.github/CODEOWNERS` file requires a review from `@senior-engineers` before any change to `environments/prod/` or `.github/` can merge.
