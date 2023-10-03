variable "instance_type_list" {
  description = "EC2 instance type"
  type = list(string)
  default = ["t2.micro", "t3.small", "t3.large"]
}

variable "instance_type_map" {
  description = "EC2 instance type"
  type = map(string)
  default = {
  "dev" = "t3.micro"
  "qa" = "t3.small"
  "prod" = "t3.large"
}

### how to use them
resource "aws_instance" "myec2vm_1" {
  ami = data.aws_ami.amzlinux2.id"
  instance_type = var.instance_type_list[1]
}

resource "aws_instance" "myec2vm_2" {
  ami = data.aws_ami.amzlinux2.id"
  instance_type = var.instance_type_map["prod"]
}





