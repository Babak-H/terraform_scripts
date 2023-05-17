# using list as variable to loop on is not possible while using foreach (unlike count)

variable "subnet_cidr_blocks" {
  description = "CIDR block for the subnets"
  type = list(string)
  default = [ "10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

##  FOREACH ##
# the result is a map of resources
resource "aws_subnet" "subnets" {
# turn list into set
  for_each = toset(var.subnet_cidr_blocks)

  vpc_id = aws_vpc.main.id
  availability_zone = "us-east-1a"
# when we use foreach, we have a variable called "each" that is same as i in for loop
# it contains key and value
  cidr_block = each.value
}

# using foreach on sets, we only have 'value' on 'each'
# using foreach on maps, we  have 'key' and 'value' on 'each'

# this is a map, each key is index and each value is the subnet itself
output "all_subnets" {
  value = aws_subnet.subnets
}

output "all_ids" {
# get the values (subnets), then specific value (here id) from all of them
  value = values(aws_subnet.subnets)[*].id
}

# when using foreach, if we remove value from map/set , it will NOT destroy and recreate 
# the whole resource group.

# ====================== inline foreach block ================
# we can have inline foreach block (only looping inside a specific part of a resource)
# this is not possible with count

variable "custom_ports" {
  description = "custom ports to open on the security groups"
  type = map(any)

  default = {
    80 = ["0.0.0.0/0"]
    8081 = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "web" {
  name = "allow-web-access"
  vpc_id = aws_vpc.main.id
# we put 'dynamic' before name of the block (here 'ingress'), and later that name becomes what we loop over
  dynamic "ingress" {
    for_each = var.custom_ports

    # this is what will be looped over
    content {
      from_port = ingress.key # 80, 81
      to_port = ingress.key # 80, 81
      protocol = "tcp"
      cidr_blocks = ingress.value # ["0.0.0.0/0"], ["10.0.0.0/16"]
    }
  }
}

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

# ===========================================
locals {
  web_servers = {
    nginx-0 = {
        instance_type = "e2-micro"
        availability_zone = "us-east1-a"
    }
    nginx-1 = {
        instance_type = "e2-micro"
        availability_zone = "us-east1-b"
    }
  }
}

resource "aws_instance" "web" {
  for_each = local.web_servers

  ami = "ami-1234567890"
  instance_type = each.value.instance_type
  availability_zone = each.value.availability_zone  # us-east1-a, us-east1-b

  tags = {
    Name = each.key  # nginx-0 , nginx-1
  }
}