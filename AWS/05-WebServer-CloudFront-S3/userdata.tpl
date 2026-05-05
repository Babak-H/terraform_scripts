#!/bin/bash
set -euxo pipefail

dnf install -y httpd php git
systemctl enable --now httpd
rm -rf /var/www/html/*
git clone https://github.com/vineets300/Webpage1.git /var/www/html
