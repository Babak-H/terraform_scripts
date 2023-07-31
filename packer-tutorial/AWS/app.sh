#!/bin/bash

sleep 30

sudo yum update -y

sudo yum install -y gcc-c++ make
curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash -
sudo yum install -y nodejs

sudo yum install unzip -y
cd ~/ && unzip my-app.zip
cd ~/my-app && npm i --only=prod

sudo mv /tmp/my-app.service /etc/systemd/system/my-app.service
sudo systemctl enable my-app.service
sudo systemctl start my-app.service