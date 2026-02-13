#!/bin/bash
set -ex
exec > /var/log/user-data.log 2>&1

yum update -y
amazon-linux-extras enable php8.0
yum clean metadata
yum install -y httpd php php-cli php-mysqlnd wget unzip curl nc amazon-efs-utils

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
  sleep 10
done

# Install WordPress
cd /var/www/html
rm -rf index.php wp-admin wp-includes *.php
curl -fL https://wordpress.org/latest.tar.gz -o latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm -f latest.tar.gz

# Mount EFS
mkdir -p /mnt/efs

until mount -t efs ${efs_id}:/ /mnt/efs; do
  sleep 10
done

echo "${efs_id}:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab

# Copy default wp-content if empty
if [ ! "$(ls -A /mnt/efs)" ]; then
  cp -r /var/www/html/wp-content/* /mnt/efs/
fi

rm -rf /var/www/html/wp-content
ln -s /mnt/efs /var/www/html/wp-content

# Configure wp-config
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/${db_name}/" wp-config.php
sed -i "s/username_here/${db_user}/" wp-config.php
sed -i "s/password_here/${db_password}/" wp-config.php
sed -i "s/localhost/${db_host}/" wp-config.php
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php

# Permissions
chown -R apache:apache /var/www/html
chown -R apache:apache /mnt/efs
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

systemctl enable httpd
systemctl start httpd
