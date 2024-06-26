locals {
  availability_zones = ["us-east-1a", "us-east-1b"]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  count = 2  # 0 1

  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr[count.index]  # local => var for external variables
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name = "public-${count.index+1}"
  }
}

resource "aws_subnet" "private" {
  count = 2
  
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name = "private-${count.index+1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-vpc-internet-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = 2
  vpc      = true
}

resource "aws_nat_gateway" "nat" {
  count = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gateway-${count.index+1}"
  }
}

resource "aws_route_table" "private" {
  count = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "private-route-table${count.index+1}"
  }
}

resource "aws_route_table_association" "private" {
  count = 2
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
