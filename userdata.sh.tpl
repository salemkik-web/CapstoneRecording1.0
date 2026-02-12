#!/bin/bash
set -e

set -o pipefail


# -------------------------------
# Logging
# -------------------------------
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "==== Starting WordPress userdata script ===="


          
# -------------------------------
# Update OS
# -------------------------------
yum update -y

# -------------------------------
# Install Apache + PHP
# -------------------------------
amazon-linux-extras enable php8.0
yum clean metadata

yum install -y \
  httpd \
  php \
  php-cli \
  php-mysqlnd \
  php-gd \
  php-curl \
  php-mbstring \
  php-xml \
  php-json \
  wget \
  unzip \
  curl \
  nc

# -------------------------------
# Start Apache
# -------------------------------
systemctl enable httpd
systemctl start httpd

# Remove default page
rm -f /var/www/html/index.html /etc/httpd/conf.d/welcome.conf

# -------------------------------
# Terraform Variables
# -------------------------------
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_HOST="${db_host}"
ALB_DNS="${alb_dns}"

echo "DB Host: $DB_HOST"

# -------------------------------
# Wait for RDS Port 3306
# -------------------------------
echo "Waiting for RDS to be reachable..."
max_retries=40
count=0
until nc -z $DB_HOST 3306; do
  count=$((count+1))
  if [ $count -ge $max_retries ]; then
    echo "RDS not reachable. Exiting."
    exit 1
  fi
  sleep 15
done


echo "RDS is reachable."

# -------------------------------
# Install WordPress
# -------------------------------
cd /var/www/html
rm -rf /var/www/html/*
curl -fL https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm -f latest.tar.gz
mv wordpress/* .
rm -rf wordpress

# -------------------------------
# Configure wp-config.php
# -------------------------------
cp wp-config-sample.php wp-config.php

sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
sed -i "s/localhost/$DB_HOST/" wp-config.php

# Add secure salts
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php

# -------------------------------
# Permissions
# -------------------------------
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;


# -------------------------------
# Restart Apache
# -------------------------------
systemctl restart httpd

echo "==== WordPress installation completed successfully ===="
