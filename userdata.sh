#!/bin/bash
yum update -y
yum install -y httpd php php-mysqlnd wget
systemctl start httpd
systemctl enable httpd

cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
chown -R apache:apache /var/www/html
