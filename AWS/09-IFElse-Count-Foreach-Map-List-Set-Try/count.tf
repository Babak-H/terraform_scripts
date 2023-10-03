provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

variable "subnet_cidr_blocks" {
  description = "CIDR block for the subnets"
  type = list(string)
  default = [ "10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

##  COUNT ##
resource "aws_subnet" "example" {
  count = length(var.subnet_cidr_blocks) # 3
  vpc_id = aws_vpc.main.id
  cidr_block = var.subnet_cidr_blocks[count.index]
  availability_zone = "us-east-1a"
}

# this will show one value
output "first_id" {
  value = aws_subnet.example[0].id
  description = "ID for first subnet"
}

# this will show a list of values
output "all_ids" {
  value = aws_subnet.example[*].id
  description = "IDs for all subnets"
}


# main issue with COUNT is that if we remove an item from the list (for example 'subnet_cidr_blocks') it will
# remove and recreate all items based on that list, because the indexing order has changed