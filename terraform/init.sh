#!/bin/bash 
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx 
sudo systemctl enable nginx
sudo aws s3 cp s3://nginx-webcontent/index.html /var/www/html/index.html
sudo systemctl restart nginx 