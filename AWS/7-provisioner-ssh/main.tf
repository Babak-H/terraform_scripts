resource "aws_instance" "Web" {
  ami = "ami-0b5eea76982371e91"
  instance_type = "t2.micro"
  count = 1
  subnet_id = aws_subnet.my_app-subnet.id
  key_name = "Web-key"
  security_groups = [aws_security_group.App_SG.id]

  # this is exactly the same as connecting to ec2 from ssh, but here done via provisioner
  provisioner "remote-exec" {
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = tls_private_key.Web-key.private_key_pem
    host = aws_instance.Web.public_ip
  }
  # these are commands that are run when we ssh into the target host
    inline = [
       "sudo yum install httpd  php git -y",
       "sudo systemctl restart httpd",
       "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "WebServer1"
  }
}


resource "aws_ebs_volume" "myebs1" {
  availability_zone = aws_instance.Web[0].availability_zone
  # size of volume in GB
  size = 1
  tags = {
    Name = "ebsvol"
  }
}

resource "aws_volume_attachment" "attach_ebs" {
  depends_on = [aws_ebs_volume.myebs1]
  device_name = "/dev/sdh"
  volume_id = aws_ebs_volume.myebs1.id
  instance_id = aws_instance.Web[0].id
  force_detach = true
}

# null_resource => used when not creating any resource, but we want to do some operation
resource "null_resource" "nullmount" {
  depends_on = [aws_volume_attachment.attach_ebs, tls_private_key.Web-key]

    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.Web-key.private_key_pem
    host     = aws_instance.Web.public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/vineets300/Webpage1.git  /var/www/html"
    ]
  }
}