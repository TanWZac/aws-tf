resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  nat_gateway_count = var.nat_gateway_mode == "none" ? 0 : var.nat_gateway_mode == "single" ? 1 : length(var.availability_zones)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 8)

  tags = {
    Name = "${var.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[var.nat_gateway_mode == "per_az" ? count.index : 0].id

  tags = {
    Name = "${var.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = local.nat_gateway_count > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[var.nat_gateway_mode == "per_az" ? count.index : 0].id
    }
  }

  tags = {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name        = "${var.name_prefix}-vpce-sg"
  description = "Security group for interface VPC endpoints."
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id], [for rt in aws_route_table.private : rt.id])

  tags = {
    Name = "${var.name_prefix}-vpce-s3"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]

  tags = {
    Name = "${var.name_prefix}-vpce-ecr-api"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]

  tags = {
    Name = "${var.name_prefix}-vpce-ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "logs" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]

  tags = {
    Name = "${var.name_prefix}-vpce-logs"
  }
}

data "aws_region" "current" {}

resource "aws_security_group" "workloads" {
  name        = "${var.name_prefix}-workloads-sg"
  description = "Base security group for workloads in private subnets."
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow all traffic from inside VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow outbound internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-workloads-sg"
  }
}

resource "aws_cloudwatch_log_group" "platform" {
  name              = "/${var.name_prefix}/platform"
  retention_in_days = 30
}

resource "aws_s3_bucket" "platform" {
  bucket = lower("${var.name_prefix}-platform-${random_id.suffix.hex}")

  tags = {
    Name = "${var.name_prefix}-platform"
  }
}

resource "aws_s3_bucket_versioning" "platform" {
  bucket = aws_s3_bucket.platform.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "platform" {
  bucket = aws_s3_bucket.platform.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "platform" {
  bucket = aws_s3_bucket.platform.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
