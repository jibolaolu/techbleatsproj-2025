resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = merge(local.common_tags, { Name = "${local.name_prefix}-VPC" })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-IGW" })
}

resource "aws_eip" "nat" {}