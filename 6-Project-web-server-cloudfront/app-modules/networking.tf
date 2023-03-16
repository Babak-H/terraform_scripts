resource "aws_vpc" "my_vpc" {
    cidr_block = var.vpc_cidr
    tags = {
        Name = "MY_VPC"
    }
}

resource "aws_subnet" "my_app-subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    depends_on = [aws_vpc.my_vpc]
    availability_zone = var.availability_zone
    tags = {
        Name = "APP_Subnet"
    }
}

resource "aws_internet_gateway" "my_IG" {
    vpc_id = aws_vpc.my_vpc.id
    depends_on = [aws_vpc.my_vpc]

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

resource "aws_route" "default_route" {
  route_table_id = aws_route_table.my_route-table.id
  gateway_id = aws_internet_gateway.my_IG.id
  destination_cidr_block = "0.0.0.0/0"
}



resource "aws_route_table_association" "App_Route_Association" {
  subnet_id = aws_subnet.my_app-subnet.id
  route_table_id = aws_route_table.my_route-table.id
}


