locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "platform" {
  source = "./modules/platform"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  nat_gateway_mode   = var.nat_gateway_mode
  enable_vpc_endpoints = var.enable_vpc_endpoints
}

module "ai" {
  source = "./modules/ai"

  name_prefix                = local.name_prefix
  vpc_id                     = module.platform.vpc_id
  private_subnet_ids         = module.platform.private_subnet_ids
  create_sagemaker_notebook  = var.create_sagemaker_notebook
  sagemaker_instance_type    = var.sagemaker_instance_type
}

module "service" {
  count  = var.enable_app_service ? 1 : 0
  source = "./modules/service"

  name_prefix       = local.name_prefix
  vpc_id            = module.platform.vpc_id
  public_subnet_ids = module.platform.public_subnet_ids
  private_subnet_ids = module.platform.private_subnet_ids

  container_image   = var.app_container_image
  container_port    = var.app_container_port
  task_cpu          = var.app_task_cpu
  task_memory       = var.app_task_memory
  desired_count     = var.app_desired_count
  min_capacity      = var.app_min_capacity
  max_capacity      = var.app_max_capacity
  health_check_path = var.app_health_check_path
  enable_https      = var.enable_alb_https
  certificate_arn   = var.alb_certificate_arn
  ssl_policy        = var.alb_ssl_policy
  enable_waf        = var.enable_waf
  waf_rate_limit    = var.waf_rate_limit
  enable_alb_access_logs            = var.enable_alb_access_logs
  enable_waf_logging                = var.enable_waf_logging
  create_edge_logs_bucket           = var.create_edge_logs_bucket
  edge_logs_bucket_name             = var.edge_logs_bucket_name
  edge_logs_prefix                  = var.edge_logs_prefix
  edge_logs_retention_days          = var.edge_logs_retention_days
  enable_edge_logs_kms_encryption   = var.enable_edge_logs_kms_encryption
  create_edge_logs_kms_key          = var.create_edge_logs_kms_key
  edge_logs_kms_key_arn             = var.edge_logs_kms_key_arn
  enable_deployment_circuit_breaker = var.enable_deployment_circuit_breaker
  deployment_rollback_on_failure    = var.deployment_rollback_on_failure
  enable_request_count_autoscaling  = var.enable_request_count_autoscaling
  request_count_target              = var.request_count_target
  request_scale_in_cooldown         = var.request_scale_in_cooldown
  request_scale_out_cooldown        = var.request_scale_out_cooldown

  enable_deletion_protection = var.enable_alb_deletion_protection
}
