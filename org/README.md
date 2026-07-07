# org/ — AWS Organization Bootstrap

Creates the AWS Organization, OU structure, and member accounts that root
`accounts.tf` references. Separate from the rest of the repo on purpose:
org management (creating/closing accounts, SCPs) and workload deployment
(VPC, ECS, etc.) should not share credentials or blast radius.

Mirrors this repo's existing `bootstrap/` pattern — local state, run once
(then occasionally, as your account structure changes), not part of the
`make plan/apply ENV=...` workflow.

## What it creates

- AWS Organization (or import an existing one — see `main.tf` comment)
- OUs: `Security`, `Workloads` → `Production` / `Development` / `Staging`
- Accounts: `log-archive`, `security-tooling` (Security OU — not deploy
  targets), `prod-primary`, optional `prod-secondary`, `dev`, `stage`
  (Workloads OU — these are what root `accounts.tf` points at)
- SCPs on the Workloads OU: deny leaving the org, restrict to approved
  regions, protect CloudTrail/GuardDuty/Config from being disabled
- Org-wide CloudTrail (bucket in the management account for now — see
  note in `cloudtrail.tf` about moving it to log-archive later)
- A monthly total-spend budget alert

## Before you run this

1. Root account MFA enabled (manual, no Terraform resource for this).
2. An IAM admin user or SSO profile in the **management account**, configured
   locally as `aws configure --profile mgmt` (or whatever `aws_profile` you set).
3. Set `management_account_id` to the management account's 12-digit ID. The
   provider refuses to run against any other account.
4. Decide your account emails — every AWS account ever created needs a
   globally unique email. `+` aliases on one inbox work fine.

## Usage

```bash
cd org
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with real values
terraform init
terraform apply
cd ..
make org-sync-accounts   # writes real account IDs into root accounts.tf
```

Account creation is async on AWS's side — first apply can take a few minutes.

## Keeping accounts.tf in sync

Root `accounts.tf` is a generated file once this module exists — see the
header comment in that file. After any change here (`terraform apply` in
`org/`), run `make org-sync-accounts` from the repo root to regenerate it.
Don't hand-edit the `id` fields in root `accounts.tf`; edit `org/main.tf`
and re-sync instead.

## What Terraform still can't do here (manual, one-time)

- **Enable IAM Identity Center** — no first-time-enable resource exists yet.
  Enable via console once; permission sets/assignments after that can be
  Terraform-managed (`aws_ssoadmin_*` resources) — ask if you want that
  module added.
- **Delegate GuardDuty/Security Hub administration** to the security-tooling
  account — needs a couple of one-time API calls before the
  `aws_guardduty_organization_configuration` /
  `aws_securityhub_organization_configuration` resources will work.

## Account deletion

Terraform cannot destroy AWS member accounts — AWS requires manual closure
via the Billing console. Every account resource here has
`prevent_destroy = true` so a stray `terraform destroy` won't try and fail
halfway through. (Same rule as `bootstrap/` — see `CLAUDE.md`.)
