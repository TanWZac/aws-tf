resource "aws_cloudwatch_log_group" "service" {
  name              = "/${var.name_prefix}/service"
  retention_in_days = var.log_retention_days
}

locals {
  create_edge_logs_bucket_effective = var.create_edge_logs_bucket || ((var.enable_alb_access_logs || (var.enable_waf && var.enable_waf_logging)) && var.edge_logs_bucket_name == null)
  create_edge_logs_kms_key_effective = var.enable_edge_logs_kms_encryption && var.create_edge_logs_kms_key && var.edge_logs_kms_key_arn == null
  edge_logs_bucket_name_effective   = local.create_edge_logs_bucket_effective ? aws_s3_bucket.edge_logs[0].bucket : var.edge_logs_bucket_name
  edge_logs_kms_key_arn_effective   = var.enable_edge_logs_kms_encryption ? (local.create_edge_logs_kms_key_effective ? aws_kms_key.edge_logs[0].arn : var.edge_logs_kms_key_arn) : null
  edge_logs_prefix_norm             = trim(var.edge_logs_prefix, "/")
  alb_log_key_prefix                = local.edge_logs_prefix_norm != "" ? "${local.edge_logs_prefix_norm}/AWSLogs/${data.aws_caller_identity.current.account_id}" : "AWSLogs/${data.aws_caller_identity.current.account_id}"
  waf_log_key_prefix                = local.edge_logs_prefix_norm != "" ? "${local.edge_logs_prefix_norm}/waf/" : "waf/"
}

data "aws_iam_policy_document" "edge_logs_kms" {
  count = local.create_edge_logs_kms_key_effective ? 1 : 0

  statement {
    sid    = "AllowAccountAdmins"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowLogDeliveryServices"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com", "logdelivery.elb.amazonaws.com", "firehose.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "edge_logs" {
  count = local.create_edge_logs_kms_key_effective ? 1 : 0

  description             = "KMS key for ${var.name_prefix} edge log encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.edge_logs_kms[0].json
}

resource "aws_kms_alias" "edge_logs" {
  count = local.create_edge_logs_kms_key_effective ? 1 : 0

  name          = "alias/${var.name_prefix}-edge-logs"
  target_key_id = aws_kms_key.edge_logs[0].key_id
}

resource "random_id" "edge_logs_suffix" {
  count = local.create_edge_logs_bucket_effective ? 1 : 0

  byte_length = 3
}

resource "aws_s3_bucket" "edge_logs" {
  count = local.create_edge_logs_bucket_effective ? 1 : 0

  bucket = lower("${var.name_prefix}-edge-logs-${random_id.edge_logs_suffix[0].hex}")

  tags = {
    Name = "${var.name_prefix}-edge-logs"
  }
}

resource "aws_s3_bucket_versioning" "edge_logs" {
  count = local.create_edge_logs_bucket_effective ? 1 : 0

  bucket = aws_s3_bucket.edge_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "edge_logs" {
  count = local.create_edge_logs_bucket_effective ? 1 : 0

  bucket = aws_s3_bucket.edge_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_edge_logs_kms_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_edge_logs_kms_encryption ? local.edge_logs_kms_key_arn_effective : null
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "edge_logs" {
  count = local.create_edge_logs_bucket_effective ? 1 : 0

  bucket = aws_s3_bucket.edge_logs[0].id

  rule {
    id     = "expire-edge-logs"
    status = "Enabled"

    filter {
      prefix = local.edge_logs_prefix_norm != "" ? "${local.edge_logs_prefix_norm}/" : ""
    }

    expiration {
      days = var.edge_logs_retention_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "edge_logs" {
  count = local.create_edge_logs_bucket_effective ? 1 : 0

  bucket = aws_s3_bucket.edge_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "edge_logs_bucket" {
  count = local.create_edge_logs_bucket_effective ? 1 : 0

  statement {
    sid    = "AllowALBLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elb.amazonaws.com", "delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.edge_logs[0].arn}/${local.alb_log_key_prefix}/*"
    ]
  }

  statement {
    sid    = "AllowALBLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elb.amazonaws.com", "delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [
      aws_s3_bucket.edge_logs[0].arn
    ]
  }
}

resource "aws_s3_bucket_policy" "edge_logs" {
  count = local.create_edge_logs_bucket_effective ? 1 : 0

  bucket = aws_s3_bucket.edge_logs[0].id
  policy = data.aws_iam_policy_document.edge_logs_bucket[0].json
}

data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name_prefix}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB ingress security group."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "service" {
  name        = "${var.name_prefix}-service-sg"
  description = "ECS service task security group."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow ALB to app tasks"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "this" {
  name               = substr(replace("${var.name_prefix}-alb", "_", "-"), 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.enable_alb_access_logs ? [1] : []
    content {
      bucket  = local.edge_logs_bucket_name_effective
      prefix  = local.edge_logs_prefix_norm != "" ? "${local.edge_logs_prefix_norm}/alb" : "alb"
      enabled = true
    }
  }
}

resource "aws_lb_target_group" "service" {
  name        = substr(replace("${var.name_prefix}-tg", "_", "-"), 0, 32)
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.service.arn
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }
}

resource "aws_wafv2_web_acl" "this" {
  count = var.enable_waf ? 1 : 0

  name  = substr(replace("${var.name_prefix}-web-acl", "_", "-"), 0, 128)
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "managed-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "IpRateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ip-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${replace(var.name_prefix, "-", "_")}_waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
}

resource "aws_iam_role" "waf_firehose" {
  count = var.enable_waf && var.enable_waf_logging ? 1 : 0

  name = "${var.name_prefix}-waf-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "waf_firehose" {
  count = var.enable_waf && var.enable_waf_logging ? 1 : 0

  name = "${var.name_prefix}-waf-firehose-s3"
  role = aws_iam_role.waf_firehose[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:s3:::${local.edge_logs_bucket_name_effective}",
            "arn:${data.aws_partition.current.partition}:s3:::${local.edge_logs_bucket_name_effective}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "logs:PutLogEvents"
          ]
          Resource = "*"
        }
      ],
      var.enable_edge_logs_kms_encryption ? [
        {
          Effect = "Allow"
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = local.edge_logs_kms_key_arn_effective
        }
      ] : []
    )
  })
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  count = var.enable_waf && var.enable_waf_logging ? 1 : 0

  name        = substr(replace("aws-waf-logs-${var.name_prefix}", "_", "-"), 0, 64)
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.waf_firehose[0].arn
    bucket_arn          = "arn:${data.aws_partition.current.partition}:s3:::${local.edge_logs_bucket_name_effective}"
    prefix              = "${local.waf_log_key_prefix}!{timestamp:yyyy/MM/dd}/"
    error_output_prefix = "${local.waf_log_key_prefix}errors/!{timestamp:yyyy/MM/dd}/"
    buffering_size      = 10
    buffering_interval  = 300
    compression_format  = "GZIP"
    kms_key_arn         = var.enable_edge_logs_kms_encryption ? local.edge_logs_kms_key_arn_effective : null
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_waf && var.enable_waf_logging ? 1 : 0

  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs[0].arn]
  resource_arn            = aws_wafv2_web_acl.this[0].arn
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-ecs-cluster"
}

resource "aws_ecs_task_definition" "service" {
  family                   = "${var.name_prefix}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      readonlyRootFilesystem = var.container_readonly_root_filesystem
      environment = var.container_environment
      secrets     = var.container_secrets
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "${var.name_prefix}-app-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  deployment_circuit_breaker {
    enable   = var.enable_deployment_circuit_breaker
    rollback = var.deployment_rollback_on_failure
  }

  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name_prefix}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.name_prefix}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = 180
    scale_out_cooldown = 90
  }
}

resource "aws_appautoscaling_policy" "request_count" {
  count = var.enable_request_count_autoscaling ? 1 : 0

  name               = "${var.name_prefix}-request-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.request_count_target

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.this.arn_suffix}/${aws_lb_target_group.service.arn_suffix}"
    }

    scale_in_cooldown  = var.request_scale_in_cooldown
    scale_out_cooldown = var.request_scale_out_cooldown
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}
