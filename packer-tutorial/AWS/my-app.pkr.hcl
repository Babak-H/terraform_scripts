packer {
 # we are using aws
 # https://developer.hashicorp.com/packer/plugins/builders/amazon
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ;]", "")
}

source "amazon-ebs" "my-app" {
 # which ami to use as the base
 # where to save the ami
  ami_name = "my-app-${local.timestamp}"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-2.*.1-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners = ["amazon"]
  }
  // source_ami = "ami-0bdb828fd58c52235"

  instance_type = "t2.micro"
  region = "us-west-2"
  ssh_username = "ec2-user"
}

build {
  # what to install
  # configure
  #  files to copy
  sources = [
    "source.amazon-ebs.my-app"
  ]

  provisioner "file" {
    source = "../myapp-zip"
    destination = "/home/ec2-user/cocktails.zip"
  }

  provisioner "file" {
    source = "./my-app.service"
    destination = "/tmp/my-app.service"
  }

  # you can even use ansible provisioner here for more advanced stuff
  provisioner "shell" {
    script = "./app.sh"
  }
}