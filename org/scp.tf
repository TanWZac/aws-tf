# org/scp.tf
# ─────────────────────────────────────────────────────────────────────────────
# Baseline guardrails. Attached at the Workloads OU level so they cover
# Production/Development/Staging without applying to the Security OU
# (log-archive/tooling accounts sometimes need broader access, e.g. multi-
# region GuardDuty aggregation).
# ─────────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "deny_leaving_org" {
  statement {
    sid       = "DenyLeaveOrganization"
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "deny_leaving_org" {
  name    = "deny-leave-organization"
  type    = "SERVICE_CONTROL_POLICY"
  content = data.aws_iam_policy_document.deny_leaving_org.json
}

resource "aws_organizations_policy_attachment" "deny_leaving_org_workloads" {
  policy_id = aws_organizations_policy.deny_leaving_org.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

# Restrict workload accounts to approved regions. Matches var.availability_zones
# region in root variables.tf — keep approved_regions in sync if you add regions.
data "aws_iam_policy_document" "region_restriction" {
  statement {
    sid    = "DenyOutsideApprovedRegions"
    effect = "Deny"
    not_actions = [
      "iam:*", "organizations:*", "route53:*", "cloudfront:*",
      "support:*", "sts:*", "budgets:*", "waf:*", "wafv2:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.approved_regions
    }
  }
}

resource "aws_organizations_policy" "region_restriction" {
  name    = "approved-regions-only"
  type    = "SERVICE_CONTROL_POLICY"
  content = data.aws_iam_policy_document.region_restriction.json
}

resource "aws_organizations_policy_attachment" "region_restriction_workloads" {
  policy_id = aws_organizations_policy.region_restriction.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

# Prevent disabling the security services the org depends on for visibility.
data "aws_iam_policy_document" "protect_security_services" {
  statement {
    sid    = "DenyDisablingSecurityServices"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:PutEventSelectors",
      "cloudtrail:UpdateTrail",
      "guardduty:DeleteDetector",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:StopMonitoringMembers",
      "config:StopConfigurationRecorder",
      "config:DeleteConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "securityhub:DisableSecurityHub",
      "securityhub:DisassociateFromAdministratorAccount",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_security_services" {
  name    = "protect-security-services"
  type    = "SERVICE_CONTROL_POLICY"
  content = data.aws_iam_policy_document.protect_security_services.json
}

locals {
  security_guardrail_target_ids = toset([
    aws_organizations_organizational_unit.workloads.id,
    aws_organizations_organizational_unit.security.id,
  ])
}

resource "aws_organizations_policy_attachment" "protect_security_services" {
  for_each = local.security_guardrail_target_ids

  policy_id = aws_organizations_policy.protect_security_services.id
  target_id = each.value
}
