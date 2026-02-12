#!/bin/bash
set -ex
exec > /var/log/user-data.log 2>&1

# Update OS
yum update -y
amazon-linux-extras enable php8.0
yum clean metadata
yum install -y httpd php php-cli php-mysqlnd wget unzip curl nc

# Start Apache
systemctl enable httpd
systemctl start httpd
rm -f /var/www/html/index.html /etc/httpd/conf.d/welcome.conf

# Wait for RDS
DB_HOST="${db_host}"
max_retries=40
count=0
until nc -z $DB_HOST 3306; do
  count=$((count+1))
  if [ $count -ge $max_retries ]; then
    echo "RDS not reachable, exiting"
    exit 1
  fi
  sleep 15
done

# Download WordPress
cd /var/www/html
rm -rf *
curl -fL https://wordpress.org/latest.tar.gz -o latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm -f latest.tar.gz

# Configure wp-config.php
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/${db_name}/" wp-config.php
sed -i "s/username_here/${db_user}/" wp-config.php
sed -i "s/password_here/${db_password}/" wp-config.php
sed -i "s/localhost/${db_host}/" wp-config.php
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php

# Permissions
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Restart Apache
systemctl restart httpd

