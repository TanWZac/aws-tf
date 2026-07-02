variable "name_prefix" {
  description = "Name prefix used for Redis resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Redis is deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the Redis subnet group."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to Redis."
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "Cache engine. Use redis for compatibility with Redis clients."
  type        = string
  default     = "redis"
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "node_count" {
  description = "Number of cache nodes. Use 2 or more for automatic failover."
  type        = number
  default     = 1
}

variable "port" {
  description = "Redis port."
  type        = number
  default     = 6379
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest."
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit."
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Optional Redis AUTH token. Store this in a secret manager for real environments."
  type        = string
  default     = null
  sensitive   = true
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots."
  type        = number
  default     = 7
}

variable "maintenance_window" {
  description = "Preferred maintenance window."
  type        = string
  default     = "sun:17:00-sun:18:00"
}
