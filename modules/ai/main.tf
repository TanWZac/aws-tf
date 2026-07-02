resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "dataset" {
  bucket = lower("${var.name_prefix}-ai-data-${random_id.suffix.hex}")

  tags = {
    Name = "${var.name_prefix}-ai-data"
  }
}

resource "aws_s3_bucket_versioning" "dataset" {
  bucket = aws_s3_bucket.dataset.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dataset" {
  bucket = aws_s3_bucket.dataset.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dataset" {
  bucket = aws_s3_bucket.dataset.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_sagemaker" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "sagemaker_execution" {
  name               = "${var.name_prefix}-sagemaker-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_sagemaker.json
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy" "s3_access" {
  name = "${var.name_prefix}-ai-s3-access"
  role = aws_iam_role.sagemaker_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.dataset.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.dataset.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_security_group" "sagemaker" {
  name        = "${var.name_prefix}-sagemaker-sg"
  description = "Security group for SageMaker notebook."
  vpc_id      = var.vpc_id

  egress {
    description = "Allow outbound internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_sagemaker_notebook_instance" "this" {
  count = var.create_sagemaker_notebook ? 1 : 0

  name                   = "${var.name_prefix}-notebook"
  role_arn               = aws_iam_role.sagemaker_execution.arn
  instance_type          = var.sagemaker_instance_type
  subnet_id              = var.private_subnet_ids[0]
  security_groups        = [aws_security_group.sagemaker.id]
  direct_internet_access = "Disabled"
}

resource "aws_ecr_repository" "models" {
  name                 = "${var.name_prefix}/model-serving"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_cloudwatch_log_group" "ai" {
  name              = "/${var.name_prefix}/ai"
  retention_in_days = 30
}
