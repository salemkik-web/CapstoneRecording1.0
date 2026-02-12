#!/bin/bash
set -e

# Log everything for debugging
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "==== Starting WordPress userdata script ===="

# Install Apache, PHP, MySQL client
yum update -y
yum install -y httpd mod_ssl php php-cli php-mysqlnd php-gd php-curl php-mbstring php-xml php-json wget unzip curl mariadb

# Start and enable Apache
systemctl enable httpd
systemctl start httpd

# Remove default Apache test page
rm -f /var/www/html/index.html /etc/httpd/conf.d/welcome.conf

# Ensure Apache listens on all interfaces
sed -i 's/^Listen .*/Listen 0.0.0.0:80/' /etc/httpd/conf/httpd.conf
systemctl restart httpd

# Terraform-injected variables
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_HOST="${db_host}"
ALB_DNS="${alb_dns}"

# Wait for RDS to be reachable
echo "Waiting for RDS at $DB_HOST..."
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" >/dev/null 2>&1; do
  echo "$(date) - RDS not ready yet, retrying in 15s..."
  sleep 15
done
echo "RDS is ready!"

# Navigate to web root
cd /var/www/html

# Download WordPress
curl -fL https://wordpress.org/latest.tar.gz -o latest.tar.gz
tar -xzf latest.tar.gz
rm -f latest.tar.gz
rsync -av wordpress/ /var/www/html/
rm -rf wordpress

# Configure wp-config.php
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
sed -i "s/localhost/$DB_HOST/" wp-config.php

# Add WordPress salts
SALT_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
sed -i "/AUTH_KEY/d" wp-config.php
echo "$SALT_KEYS" >> wp-config.php

# Install WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Set site URL via WP-CLI
until wp option update siteurl "http://$ALB_DNS" --allow-root >/dev/null 2>&1; do
  echo "$(date) - WP-CLI not ready yet, retrying in 10s..."
  sleep 10
done
wp option update home "http://$ALB_DNS" --allow-root

# Set permissions
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Restart Apache
systemctl restart httpd

echo "==== WordPress userdata script completed! ===="
