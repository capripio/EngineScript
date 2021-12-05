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

# Check current user's ID. If user is not 0 (root), exit.
if [ "${EUID}" != 0 ];
  then
    echo "${BOLD}ALERT:${NORMAL}"
    echo "EngineScript should be executed as the root user."
    exit
fi

#----------------------------------------------------------------------------
# Start Main Script

# Retrieve EngineScript Nginx Configuration
cp -a /usr/local/bin/enginescript/etc/nginx/. /etc/nginx/

# Tune FastCGI Cache
sed -i "s|SEDSERVERMEM03|${SERVER_MEMORY_TOTAL_03}|g" /etc/nginx/nginx.conf
sed -i "s|SEDSERVERMEM05|${SERVER_MEMORY_TOTAL_05}|g" /etc/nginx/nginx.conf

# Assign Permissions
chown -R www-data:www-data /etc/nginx
chown -R www-data:www-data /usr/lib/nginx/modules
chown -R www-data:www-data /var/cache/nginx
chown -R www-data:www-data /var/lib/nginx
chown -R www-data:www-data /var/log/domains
chown -R www-data:www-data /var/www
chmod 775 /var/cache/nginx

# Logrotate - Nginx and Domains
cp -rf /usr/local/bin/enginescript/etc/logrotate.d/nginx /etc/logrotate.d/nginx
cp -rf /usr/local/bin/enginescript/etc/logrotate.d/domains /etc/logrotate.d/domains
find /etc/logrotate.d -type f -exec chmod 644 {} \;
