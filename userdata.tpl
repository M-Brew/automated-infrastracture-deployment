#!/bin/bash
apt update -y &&
apt install -y nginx
echo "Hello World" > /var/www/html/index.html