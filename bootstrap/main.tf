# bootstrap/main.tf
# ─────────────────────────────────────────────────────────────────────────────
# Creates the S3 bucket and DynamoDB table needed for Terraform remote state.
# Run ONCE before any other Terraform in this repo.
#
# Usage:
#   cd bootstrap
#   terraform init          # uses local state — no backend needed
#   terraform apply
#   # Copy outputs into environments/*/backend.hcl
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6.0"
  # Intentionally local state — this module bootstraps the remote state backend.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ── S3 state bucket ───────────────────────────────────────────────────────────

resource "aws_s3_bucket" "state" {
  bucket = "${var.project_name}-tf-state-${random_id.suffix.hex}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "${var.project_name}-tf-state"
    ManagedBy = "terraform-bootstrap"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ── DynamoDB lock table ───────────────────────────────────────────────────────

resource "aws_dynamodb_table" "lock" {
  name         = "${var.project_name}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "${var.project_name}-tf-locks"
    ManagedBy = "terraform-bootstrap"
  }
}
