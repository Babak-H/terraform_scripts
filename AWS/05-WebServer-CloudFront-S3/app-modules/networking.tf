resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "MY_VPC"
  }
}

resource "aws_subnet" "my_app-subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  # public subnet
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "APP_Subnet"
  }
}

resource "aws_internet_gateway" "my_IG" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MY_IGW"
  }
}

resource "aws_route_table" "my_route-table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MY_Route_table"
  }
}

# all the traffic that reaches this routeTable will by default go to the internet
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.my_route-table.id
  gateway_id             = aws_internet_gateway.my_IG.id
  destination_cidr_block = "0.0.0.0/0"
}

# associate the route table with the subnet
resource "aws_route_table_association" "App_Route_Association" {
  subnet_id      = aws_subnet.my_app-subnet.id
  route_table_id = aws_route_table.my_route-table.id
}
