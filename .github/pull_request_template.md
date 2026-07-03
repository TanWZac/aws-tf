## Summary

<!-- What does this PR change in infrastructure? -->

## Type of change

- [ ] New resource
- [ ] Resource modification
- [ ] Deletion / removal
- [ ] Module update
- [ ] Variable / output change
- [ ] CI / pre-commit change

## Environments affected

- [ ] dev
- [ ] stage
- [ ] prod

## Terraform plan reviewed

<!-- Paste or link the plan output from CI artifacts -->

- [ ] Plan reviewed — no unintended `destroy` or `replace` operations
- [ ] Destructive changes are intentional and approved
- [ ] `terraform validate` passes
- [ ] `terraform fmt` applied

## Checklist

- [ ] No secrets or credentials in this PR
- [ ] `checks.tf` assertions still pass
- [ ] New variables added to all `environments/*/terraform.tfvars.example` files
- [ ] New SSM outputs documented in `contracts/ssm-parameters.yaml` (aws-platform repo)
- [ ] Bootstrap (`bootstrap/`) changes tested separately if applicable
- [ ] `prevent_destroy` lifecycle considered for stateful resources
