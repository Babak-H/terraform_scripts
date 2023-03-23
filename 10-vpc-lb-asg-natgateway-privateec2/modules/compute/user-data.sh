#!/bin/bash
yum update -y
yum install -y httpd
systemctl restart httpd && systemctl enable httpd