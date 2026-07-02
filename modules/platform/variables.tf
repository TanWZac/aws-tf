variable "name_prefix" {
  description = "Common name prefix for resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones used for subnet placement."
  type        = list(string)
}

variable "nat_gateway_mode" {
  description = "NAT mode for private subnets: none, single, or per_az."
  type        = string
}

variable "enable_vpc_endpoints" {
  description = "Whether to create VPC endpoints for core AWS services."
  type        = bool
}
