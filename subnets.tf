resource "aws_nat_gateway" "tbs-natgw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-NatGateway" })
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-public-subnet" })
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-private-subnet" })
}

resource "aws_route_table" "tbs-public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-public-RT" })
}

resource "aws_route_table_association" "public-rt-assctn" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.tbs-public-rt.id
}

resource "aws_route_table" "tbs-private-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tbs-natgw.id
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-private-RT" })
}

resource "aws_route_table_association" "private-rt-assctn" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.tbs-private-rt.id
}

