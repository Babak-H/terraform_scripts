# ========= IF ================================================

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

variable "enable_database_vpc" {
  default = true
}

# using conditional statements to create the resource or not, with count
resource "aws_vpc" "database" {
# <CONDITIONAL> ? <TRUE_VAL> : <FALSE_VAL>
  count = var.enable_database_vpc ? 1 : 0

  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "database"
  }
}

# ========= IF-ELSE ================================================

variable "enable_public" {
  default = false
}

resource "aws_subnet" "public" {
# this is same as above, count is 1 when variable is True
  count = var.enable_public ? 1 : 0

  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/19"
}

resource "aws_subnet" "private" {
# here we have change 1:0 to 0:1, so count is 0 when variable true, 1 when it is false
  count = var.enable_public ? 0 : 1
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/19"
}

# here we might have some issue, due to index changes later
output "subnet_id" {
  value = (
    var.enable_public ? aws_subnet.public[0].id : aws_subnet.private[0].id
  )
}

# this is the better version
output "subnet_id_v2" {
 value = one(concat(
    aws_subnet.public[*].id, aws_subnet.private[*].id
 )) 
}

# concat(["a", ""], ["b", "c"]) => ["a", "b", "c"]

# one([]) => null
# one(["a"]) => a
# one(["a", "b"]) => Error