resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.this.id
  cidr_block = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    { Name = "${var.env}-private-${var.azs[count.index]}" },
    var.private_subnet_tags
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.this.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    { Name = "${var.env}-public-${var.azs[count.index]}" },
    var.public_subnet_tags
  )
}


# resource "aws_subnet" "private_us_east_1a" {
#   vpc_id = aws_vpc.main.id
#   cidr_block = "10.0.0.0/19"
#   availability_zone = "us-east-1a"

#   tags = {
#     "Name" = "dev-private-us-east-1a"
#     # tags needed for kubernetes to create internal loadbalacer and detect subnets
#     "kubernetes.io/role/internal-elb" = "1"
#     "kubernetes.io/cluster/dev-demo" = "owned"
#   }
# }

# resource "aws_subnet" "private_us_east_1b" {
#   vpc_id = aws_vpc.main.id
#   cidr_block = "10.0.32.0/19"
#   availability_zone = "us-east-1b"

#   tags = {
#     "Name" = "dev-private-us-east-1b"
#     "kubernetes.io/role/internal-elb" = "1"
#     "kubernetes.io/cluster/dev-demo" = "owned"
#   }
# }

