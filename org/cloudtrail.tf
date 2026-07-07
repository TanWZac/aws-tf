# org/cloudtrail.tf
# ─────────────────────────────────────────────────────────────────────────────
# Org-wide CloudTrail with constrained service-principal access, KMS encryption,
# retention, and log-file validation. The bucket still lives in the management
# account for this first version; move it to log-archive with a cross-account
# provider/role when you want stricter separation.
# ─────────────────────────────────────────────────────────────────────────────

data "aws_partition" "current" {}

locals {
  org_trail_name       = "${var.project_name}-org-trail"
  org_trail_source_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${var.management_account_id}:trail/${local.org_trail_name}"
  org_cloudtrail_write_prefixes = [
    "AWSLogs/${var.management_account_id}",
    "AWSLogs/${aws_organizations_organization.this.id}",
  ]
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.project_name}-${var.management_account_id}-org-cloudtrail-logs"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "cloudtrail_kms_key" {
  statement {
    sid    = "AllowManagementAccountAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.management_account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailEncryptLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.management_account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.org_trail_source_arn]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${var.management_account_id}:trail/*"]
    }
  }
}

resource "aws_kms_key" "cloudtrail_logs" {
  description             = "KMS key for ${var.project_name} organization CloudTrail logs"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudtrail_kms_key.json

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "cloudtrail_logs" {
  name          = "alias/${var.project_name}-org-cloudtrail-logs"
  target_key_id = aws_kms_key.cloudtrail_logs.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail_logs.arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "retain-org-cloudtrail-logs"
    status = "Enabled"

    filter {
      prefix = "AWSLogs/"
    }

    expiration {
      days = var.cloudtrail_log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.management_account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.org_trail_source_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      for prefix in local.org_cloudtrail_write_prefixes : "${aws_s3_bucket.cloudtrail_logs.arn}/${prefix}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.management_account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.org_trail_source_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

resource "aws_cloudtrail" "org_trail" {
  name                          = local.org_trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  kms_key_id                    = aws_kms_key.cloudtrail_logs.arn
  is_organization_trail         = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}
