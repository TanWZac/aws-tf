terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  allowed_account_ids = ["414819400869"]

  default_tags {
    tags = {
      Project     = "lead-agent"
      Environment = "stage"
      ManagedBy   = "terraform"
    }
  }
}

module "lead_agent_dashboard" {
  source = "../../../modules/service"

  name_prefix = "lead-agent-dashboard"

  vpc_id             = "vpc-0b0569070ef84ada8"
  public_subnet_ids  = ["subnet-016b5b925e9880712", "subnet-0b6ea10bb3cf78ae0"]
  private_subnet_ids = ["subnet-016b5b925e9880712"]

  existing_ecs_cluster_id   = "arn:aws:ecs:ap-southeast-2:414819400869:cluster/lead-agent-cluster"
  existing_ecs_cluster_name = "lead-agent-cluster"

  container_image   = "414819400869.dkr.ecr.ap-southeast-2.amazonaws.com/lead-agent:c91ea1e"
  container_port    = 8501
  task_cpu          = 256
  task_memory       = 512
  desired_count     = 2
  min_capacity      = 2
  max_capacity      = 2
  health_check_path = "/"

  task_role_arn = "arn:aws:iam::414819400869:role/lead-agent-task-role"

  existing_task_execution_role_arn = "arn:aws:iam::414819400869:role/lead-agent-task-execution-role"

  ecs_service_name       = "lead-agent-dashboard-service"
  task_family            = "lead-agent-dashboard-task"
  container_name         = "lead-agent-dashboard-container"
  efs_volume_name        = "lead-agent-data"
  alb_sg_description     = "ALB for lead-agent dashboard - inbound 80 restricted to admin IP"
  service_sg_description = "Streamlit dashboard for lead-agent - inbound 8501 restricted to admin IP"
  service_sg_name        = "lead-agent-dashboard-sg"

  log_group_name        = "/ecs/lead-agent-dashboard"
  awslogs_stream_prefix = "dashboard"
  container_command = [
    "streamlit", "run", "agent/streamlit_app.py",
    "--server.port=8501", "--server.address=0.0.0.0",
    "--server.headless=true",
  ]

  omit_readonly_root_filesystem = true
  omit_container_secrets        = true

  enable_efs_volume        = true
  efs_file_system_id       = "fs-046bef46c5fb9c780"
  efs_access_point_id      = "fsap-07943c6b0b556df57"
  efs_container_mount_path = "/app/data"
  efs_read_only            = true

  container_environment = [
    { name = "DB_PATH", value = "/app/data/enquiries.db" },
    { name = "DB_READ_ONLY", value = "1" },
  ]

  alb_allowed_cidr_blocks = ["58.84.150.77/32"]

  enable_https    = false
  certificate_arn = null
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  enable_waf     = false
  waf_rate_limit = 2000

  enable_deletion_protection = true
  enable_alb_access_logs     = false
  enable_waf_logging         = false
  create_edge_logs_bucket    = false
  edge_logs_bucket_name      = null
  edge_logs_prefix           = "edge"
  edge_logs_retention_days   = 30

  enable_edge_logs_kms_encryption = false
  create_edge_logs_kms_key        = false
  edge_logs_kms_key_arn           = null

  enable_deployment_circuit_breaker = true
  deployment_rollback_on_failure    = true
  enable_request_count_autoscaling  = false
  request_count_target              = 1000
  request_scale_in_cooldown         = 180
  request_scale_out_cooldown        = 60

  enable_alarms      = true
  alarm_email        = null
  log_retention_days = 30
  environment        = "stage"
}

output "dashboard_alb_dns_name" {
  value = module.lead_agent_dashboard.alb_dns_name
}

output "dashboard_alerts_sns_topic_arn" {
  value = module.lead_agent_dashboard.alerts_sns_topic_arn
}
