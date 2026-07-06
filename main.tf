locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "platform" {
  source = "./modules/platform"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  nat_gateway_mode     = var.nat_gateway_mode
  enable_vpc_endpoints = var.enable_vpc_endpoints
}

module "ai" {
  source = "./modules/ai"

  name_prefix               = local.name_prefix
  vpc_id                    = module.platform.vpc_id
  private_subnet_ids        = module.platform.private_subnet_ids
  create_sagemaker_notebook = var.create_sagemaker_notebook
  sagemaker_instance_type   = var.sagemaker_instance_type
}

module "service" {
  count  = var.enable_app_service ? 1 : 0
  source = "./modules/service"

  name_prefix        = local.name_prefix
  vpc_id             = module.platform.vpc_id
  public_subnet_ids  = module.platform.public_subnet_ids
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

  enable_alb_access_logs          = var.enable_alb_access_logs
  enable_waf_logging              = var.enable_waf_logging
  create_edge_logs_bucket         = var.create_edge_logs_bucket
  edge_logs_bucket_name           = var.edge_logs_bucket_name
  edge_logs_prefix                = var.edge_logs_prefix
  edge_logs_retention_days        = var.edge_logs_retention_days
  enable_edge_logs_kms_encryption = var.enable_edge_logs_kms_encryption
  create_edge_logs_kms_key        = var.create_edge_logs_kms_key
  edge_logs_kms_key_arn           = var.edge_logs_kms_key_arn

  enable_deployment_circuit_breaker = var.enable_deployment_circuit_breaker
  deployment_rollback_on_failure    = var.deployment_rollback_on_failure
  enable_request_count_autoscaling  = var.enable_request_count_autoscaling
  request_count_target              = var.request_count_target
  request_scale_in_cooldown         = var.request_scale_in_cooldown
  request_scale_out_cooldown        = var.request_scale_out_cooldown

  enable_deletion_protection = var.enable_alb_deletion_protection
  environment                = var.environment
}

module "api_gateway" {
  count  = var.enable_api_gateway && var.enable_app_service ? 1 : 0
  source = "./modules/api_gateway"

  name_prefix = local.name_prefix
  backend_url = var.enable_alb_https ? "https://${module.service[0].alb_dns_name}" : "http://${module.service[0].alb_dns_name}"

  stage_name                = var.api_gateway_stage_name
  allowed_origins           = var.api_gateway_allowed_origins
  allowed_methods           = var.api_gateway_allowed_methods
  allowed_headers           = var.api_gateway_allowed_headers
  access_log_retention_days = var.api_gateway_access_log_retention_days
  throttling_burst_limit    = var.api_gateway_throttling_burst_limit
  throttling_rate_limit     = var.api_gateway_throttling_rate_limit
  custom_domain_name        = var.api_gateway_custom_domain_name
  certificate_arn           = var.api_gateway_certificate_arn
  auto_deploy               = var.api_gateway_auto_deploy
  enable_jwt_authorizer     = var.api_gateway_enable_jwt_authorizer
  jwt_issuer                = var.api_gateway_jwt_issuer
  jwt_audiences             = var.api_gateway_jwt_audiences
  environment               = var.environment
}

module "redis" {
  count  = var.enable_redis ? 1 : 0
  source = "./modules/redis"

  name_prefix        = local.name_prefix
  vpc_id             = module.platform.vpc_id
  private_subnet_ids = module.platform.private_subnet_ids

  allowed_security_group_ids = concat(
    [module.platform.workloads_security_group_id],
    var.enable_app_service ? [module.service[0].service_security_group_id] : []
  )

  engine                     = var.redis_engine
  engine_version             = var.redis_engine_version
  node_type                  = var.redis_node_type
  node_count                 = var.redis_node_count
  port                       = var.redis_port
  at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
  transit_encryption_enabled = var.redis_transit_encryption_enabled
  auth_token                 = var.redis_auth_token
  snapshot_retention_limit   = var.redis_snapshot_retention_limit
  maintenance_window         = var.redis_maintenance_window
}

module "frontend" {
  count  = var.enable_frontend ? 1 : 0
  source = "./modules/frontend"

  name_prefix = local.name_prefix
  environment = var.environment
  price_class = var.frontend_price_class

  custom_domain_name = var.frontend_custom_domain_name
  certificate_arn    = var.frontend_certificate_arn
}

module "cognito" {
  count  = var.enable_cognito ? 1 : 0
  source = "./modules/cognito"

  name_prefix        = local.name_prefix
  environment        = var.environment
  callback_urls      = var.cognito_callback_urls
  logout_urls        = var.cognito_logout_urls
  auth_domain_prefix = var.cognito_auth_domain_prefix
}
