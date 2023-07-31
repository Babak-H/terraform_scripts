#!/bin/bash

apt-get -o DPkg::Lock::Timeout=-1 install nginx -y
systemctl enable nginx
