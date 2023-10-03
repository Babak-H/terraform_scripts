resource "aws_eip" "this" {
  vpc = true

  tags = {
    Name = "${var.env}-nat"
  }
}

resource "aws_nat_gateway" "this" {
  # assign elastic ip to the nat gateway
  allocation_id = aws_eip.this.id
 # put nat gateway in one of the public subnets   
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.env}-nat"
  }
  # associate nat gateway with internet gateway
  depends_on = [aws_internet_gateway.this]
}