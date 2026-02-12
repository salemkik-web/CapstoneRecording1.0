#!/bin/bash
set -e
set -o pipefail

# -------------------------------
# Logging
# -------------------------------
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "==== Starting WordPress userdata script ===="

# -------------------------------
# Update OS and install packages
# -------------------------------
yum update -y
amazon-linux-extras enable php8.0 -y
amazon-linux-extras enable mysql8.0 -y   # MySQL 8 client
yum clean metadata
yum install -y httpd mod_ssl php php-cli php-mysqlnd php-gd php-curl php-mbstring php-xml php-json wget unzip curl mysql

# -------------------------------
# Start Apache
# -------------------------------
systemctl enable httpd
systemctl start httpd

# Remove default Apache test page
rm -f /var/www/html/index.html /etc/httpd/conf.d/welcome.conf

# Ensure Apache listens on all interfaces
sed -i 's/^Listen .*/Listen 0.0.0.0:80/' /etc/httpd/conf/httpd.conf
systemctl restart httpd

# -------------------------------
# Terraform-injected variables
# -------------------------------
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_HOST="${db_host}"
ALB_DNS="${alb_dns}"

# -------------------------------
# Wait for RDS to be ready
# -------------------------------
max_retries=40
count=0
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" >/dev/null 2>&1; do
  count=$((count+1))
  echo "$(date) - RDS not ready yet, retry $count/$max_retries..."
  sleep 15
  if [ $count -ge $max_retries ]; then
    echo "RDS not reachable after $((15*max_retries/60)) minutes. Exiting."
    exit 1
  fi
done
echo "RDS is ready!"

# -------------------------------
# Prepare WordPress web root
# -------------------------------
cd /var/www/html
rm -rf /var/www/html/*

# Download WordPress
for i in {1..5}; do
  curl -fL https://wordpress.org/latest.tar.gz -o latest.tar.gz && break
  echo "Retry $i failed, waiting 10s..."
  sleep 10
  if [ $i -eq 5 ]; then
    echo "Failed to download WordPress. Exiting."
    exit 1
  fi
done

# Extract WordPress
tar -xzf latest.tar.gz
rm -f latest.tar.gz
rsync -av wordpress/ ./
rm -rf wordpress

# -------------------------------
# Configure wp-config.php
# -------------------------------
cp wp-config-sample.php wp-config.php
chmod 600 wp-config.php
sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
sed -i "s/localhost/$DB_HOST/" wp-config.php

# Add secure salts
SALT_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
sed -i "/AUTH_KEY/,/NONCE_SALT/d" wp-config.php
echo "$SALT_KEYS" >> wp-config.php

# -------------------------------
# Install WP-CLI
# -------------------------------
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# -------------------------------
# Wait for DB connection via WP-CLI
# -------------------------------
timeout=600
elapsed=0
until wp db check --allow-root >/dev/null 2>&1 || [ $elapsed -ge $timeout ]; do
  echo "$(date) - WP-CLI DB not ready, retrying..."
  sleep 10
  elapsed=$((elapsed+10))
done
if [ $elapsed -ge $timeout ]; then
  echo "WP-CLI could not connect to DB after 10 minutes. Exiting."
  exit 1
fi

# -------------------------------
# Set site URL to ALB DNS
# -------------------------------
for i in {1..10}; do
  wp option update siteurl "http://$ALB_DNS" --allow-root && \
  wp option update home "http://$ALB_DNS" --allow-root && break
  echo "WP-CLI site/home not ready, retry $i..."
  sleep 10
done

# -------------------------------
# Set correct permissions
# -------------------------------
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Restart Apache
systemctl restart httpd

echo "==== WordPress userdata script completed successfully! ===="
