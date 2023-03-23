#!/bin/bash
sudo yum install httpd  php git -y
sudo systemctl restart httpd
sudo systemctl enable httpd
sudo rm -rf /var/www/html/*
sudo git clone https://github.com/vineets300/Webpage1.git  /var/www/html