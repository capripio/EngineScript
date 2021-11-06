#!/usr/bin/env bash
#----------------------------------------------------------------------------
# EngineScript - High-Performance WordPress LEMP Server
#----------------------------------------------------------------------------
# Website:      https://EngineScript.com
# GitHub:       https://github.com/Enginescript/EngineScript
# Company:      VisiStruct / EngineScript
# License:      GPL v3.0
# OS:           Ubuntu 20.04 (focal)
#----------------------------------------------------------------------------

# EngineScript Variables
source /usr/local/bin/enginescript/enginescript-variables.txt
source /home/EngineScript/enginescript-install-options.txt

#----------------------------------------------------------------------------
# Forked from https://github.com/A5hleyRich/simple-automated-tasks

# Include config
source /home/EngineScript/sites-list/sites.sh

for i in "${SITES[@]}"
do
	cd "$ROOT/$i/html"
	# Files
	find . -type f -exec chmod 644 {} +

	# Directories
	find . -type d -exec chmod 755 {} +

	# wp-config.php
	chmod 600 wp-config.php

	# Ownership
	chown -R www-data:www-data *

  # Make wp-cron executable
  chmod +x wp-cron.php
done

# Assign Nginx Permissions
chown -R www-data:www-data /etc/nginx
chown -R www-data:www-data /usr/lib/nginx/modules
chown -R www-data:www-data /var/cache/nginx
chown -R www-data:www-data /var/lib/nginx
chown -R www-data:www-data /var/log/domains
chown -R www-data:www-data /var/www
chmod 775 /var/cache/nginx

# Assign PHP Opcache Permissions
chown -R www-data:www-data /var/cache/opcache
chmod 775 /var/cache/opcache

# Assign EngineScript Permissions
chmod -R 755 /usr/local/bin/enginescript
chown -R root:root /usr/local/bin/enginescript
