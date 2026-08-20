variable "enable_redis" {
  description = "Whether to provision Redis/ElastiCache for platform services."
  type        = bool
  default     = false
}

variable "redis_engine" {
  description = "Cache engine used by the Redis module."
  type        = string
  default     = "redis"
}

variable "redis_engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "ElastiCache node type for Redis."
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_node_count" {
  description = "Number of Redis cache nodes. Use 2 or more for failover."
  type        = number
  default     = 1

  validation {
    condition     = !var.enable_redis || var.redis_node_count >= 1
    error_message = "redis_node_count must be at least 1 when Redis is enabled."
  }

  validation {
    condition     = !(var.enable_redis && var.environment == "prod") || var.redis_node_count >= 2
    error_message = "prod Redis requires redis_node_count >= 2 for automatic failover."
  }
}

variable "redis_port" {
  description = "Redis port."
  type        = number
  default     = 6379
}

variable "redis_at_rest_encryption_enabled" {
  description = "Enable Redis encryption at rest."
  type        = bool
  default     = true
}

variable "redis_transit_encryption_enabled" {
  description = "Enable Redis encryption in transit."
  type        = bool
  default     = true
}

variable "redis_auth_token" {
  description = "Optional Redis auth token. Prefer a secret-backed value for real environments."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = !(var.enable_redis && var.environment == "prod") || var.redis_auth_token != null
    error_message = "prod Redis requires redis_auth_token. Private subnets are not authentication."
  }
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots."
  type        = number
  default     = 7
}

variable "redis_maintenance_window" {
  description = "Preferred Redis maintenance window."
  type        = string
  default     = "sun:17:00-sun:18:00"
}
