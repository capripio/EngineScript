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

# Intro Warning
echo ""
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo "|   Domain Creation                                   |"
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo ""
echo "WARNING: Do not run this script on a site that already exists."
echo "If you do, things will break."
echo ""
sleep 1

# Domain Input
echo "For domain name, enter only the domain without https:// or trailing /"
echo "note:   lowercase text only"
echo ""
echo "Examples:    yourdomain.com"
echo "             yourdomain.net"
echo ""
read -p "Enter Domain name: " DOMAIN
echo ""
echo "You entered:  ${DOMAIN}"
echo "SITE_URL=${DOMAIN}" >> /home/EngineScript/mysql-credentials/${DOMAIN}.txt
echo ""
echo ""

# Add Domain to Site List
sed -i "\/SITES\=(/a\
\"$DOMAIN\"" /home/EngineScript/sites-list/sites.sh

# Create Nginx Vhost File
cp -p /usr/local/bin/enginescript/etc/nginx/sites-available/yourdomain.com.conf /etc/nginx/sites-enabled/${DOMAIN}.conf
sed -i "s|yourdomain.com|${DOMAIN}|g" /etc/nginx/sites-enabled/${DOMAIN}.conf

# Create Origin Certificate
mkdir -p /etc/nginx/ssl/${DOMAIN}

# Final Cloudflare SSL Steps
clear

echo ""
echo "Go to the Cloudflare Dashboard."
echo "  1. Select your site."
echo "  2. Click on the SSL/TLS tab."
echo ""
echo "Click on the Overview section."
echo "  1. Set the SSL mode to Full (Strict)"
echo ""
echo "Still in the SSL/TLS tab, click on the Edge Certificates section."
echo "  1.  Set Always Use HTTPS to Off (Important: This can cause redirect loops)."
echo "  2.  We recommend enabling HSTS. Turning off HSTS will make your site unreachable until the Max-Age time expires. This is a setting you want to set once and leave on forever."
echo "  3.  Set Minimum TLS Version to TLS 1.2."
echo "  4.  Enable Opportunistic Encryption"
echo "  5.  Enable TLS 1.3"
echo "  6.  Enable Automatic HTTPS Rewrites"
echo ""
echo "Still in the SSL/TLS tab, click on the Origin Server section."
echo "  1.  Set Authenticated Origin Pulls to On."
echo ""
echo "Click on the Network tab."
echo "  1.  Enable HTTP/2"
echo "  2.  Enable HTTP/3 (with QUIC)"
echo "  3.  Enable 0-RTT Connection Resumption"
echo "  4.  Enable IPv6 Compatibility"
echo "  5.  Enable gRPC"
echo "  6.  Enable WebSockets"
echo "  7.  Enable Onion Routing"
echo "  8.  Enable Pseudo IPv4"
echo "  9.  Enable IP Geolocation"
echo ""

while true;
  do
    read -p "When finished, enter y to continue to the next step: " y
      case $y in
        [Yy]* )
          echo "Let's continue";
          sleep 1;
          break
          ;;
        * ) echo "Please answer y";;
      esac
  done

# Cloudflare Keys
export CF_Key="${CF_GLOBAL_API_KEY}"
export CF_Email="${CF_ACCOUNT_EMAIL}"

/root/.acme.sh/acme.sh --issue --dns dns_cf --server letsencrypt -d ${DOMAIN} -d *.${DOMAIN} -k ec-384

/root/.acme.sh/acme.sh --install-cert -d ${DOMAIN} --ecc \
--cert-file /etc/nginx/ssl/${DOMAIN}/cert.pem \
--key-file /etc/nginx/ssl/${DOMAIN}/key.pem \
--fullchain-file /etc/nginx/ssl/${DOMAIN}/fullchain.pem \
--ca-file /etc/nginx/ssl/${DOMAIN}/ca.pem \
--reloadcmd "date"

# Domain Creation Variables
PREFIX="${RAND_CHAR2}"
SDB="ES${RAND_CHAR8}"
SUSR="${RAND_CHAR16}"
SPS="${RAND_CHAR32}"

# Domain Database Credentials
echo "DB=${SDB}" >> /home/EngineScript/mysql-credentials/${DOMAIN}.txt
echo "USR=${SUSR}" >> /home/EngineScript/mysql-credentials/${DOMAIN}.txt
echo "PSWD=${SPS}" >> /home/EngineScript/mysql-credentials/${DOMAIN}.txt
echo ""

sleep 2

source /home/EngineScript/mysql-credentials/${DOMAIN}.txt

echo "Randomly generated MySQL database credentials for ${SITE_URL}."
echo ""

sleep 2

mysql -u root -p$MARIADB_ADMIN_PASSWORD -e "CREATE DATABASE ${DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;"
mysql -u root -p$MARIADB_ADMIN_PASSWORD -e "CREATE USER ${USR}@'localhost' IDENTIFIED BY '${PSWD}';"
mysql -u root -p$MARIADB_ADMIN_PASSWORD -e "GRANT index, select, insert, delete, update, create, drop, alter, create temporary tables, execute, lock tables, create view, show view, create routine, alter routine, trigger ON ${DB}.* TO ${USR}@'localhost'; FLUSH PRIVILEGES;"

# Backup Dir Creation
mkdir -p /home/EngineScript/site-backups/${SITE_URL}/nginx
mkdir -p /home/EngineScript/site-backups/${SITE_URL}/ssl-keys
mkdir -p /home/EngineScript/site-backups/${SITE_URL}/wp-config
mkdir -p /home/EngineScript/site-backups/${SITE_URL}/wp-database
mkdir -p /home/EngineScript/site-backups/${SITE_URL}/wp-uploads

# Site Root
mkdir -p /var/www/sites/${SITE_URL}/html
cd /var/www/sites/${SITE_URL}/html

# Domain Logs
mkdir -p /var/log/domains/${SITE_URL}
touch /var/log/domains/${SITE_URL}/${SITE_URL}-wp-error.log
chown -R www-data:www-data /var/log/domains/${SITE_URL}

# Download WordPress using WP-CLI
wp core download --allow-root
rm -f /var/www/sites/${SITE_URL}/html/wp-content/plugins/hello.php

# Download WordPress (old method)
#wget https://wordpress.org/latest.tar.gz
#tar -xzvf latest.tar.gz
#mv wordpress/* .
#rmdir /var/www/sites/${SITE_URL}/html/wordpress
#rm -f /var/www/sites/${SITE_URL}/html/wp-content/plugins/hello.php
#mkdir -p /var/www/sites/${SITE_URL}/html/wp-content/uploads

# Create wp-config.php
cp -p /usr/local/bin/enginescript/var/www/wordpress/wp-config.php /var/www/sites/${SITE_URL}/html/wp-config.php
sed -i "s|SEDWPDB|${DB}|g" /var/www/sites/${SITE_URL}/html/wp-config.php
sed -i "s|SEDWPUSER|${USR}|g" /var/www/sites/${SITE_URL}/html/wp-config.php
sed -i "s|SEDWPPASS|${PSWD}|g" /var/www/sites/${SITE_URL}/html/wp-config.php
sed -i "s|SEDPREFIX|${PREFIX}|g" /var/www/sites/${SITE_URL}/html/wp-config.php
sed -i "s|SEDURL|${SITE_URL}|g" /var/www/sites/${SITE_URL}/html/wp-config.php

# WP Salt Creation
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s /var/www/sites/${SITE_URL}/html/wp-config.php

# WP Scan API Token
sed -i "s|SEDWPSCANAPI|${WPSCANAPI}|g" /var/www/sites/${SITE_URL}/html/wp-config.php

# Create robots.txt
cp -p /usr/local/bin/enginescript/var/www/wordpress/robots.txt /var/www/sites/${SITE_URL}/html/robots.txt
sed -i "s|SEDURL|${SITE_URL}|g" /var/www/sites/${SITE_URL}/html/robots.txt

# WP File Permissions
find /var/www/sites/${SITE_URL} -type d -exec chmod 755 {} \;
find /var/www/sites/${SITE_URL} -type f -exec chmod 644 {} \;
chown -R www-data:www-data /var/www/sites/${SITE_URL}
chmod +x /var/www/sites/${SITE_URL}/html/wp-cron.php
chmod 600 /var/www/sites/${SITE_URL}/html/wp-config.php

# WP-CLI Finalizing Install
clear
echo "============================================="
echo "Finalizing ${SITE_URL} Install:"
echo "============================================="

# Ask user to continue install
#while true;
  #do
    #read -p "When ready, enter y to begin finalizing ${SITE_URL}: " y
      #case $y in
        #[Yy]* )
          #echo "Let's continue";
          #sleep 1;
          #break
          #;;
        #* ) echo "Please answer y";;
      #esac
  #done

# WP-CLI Install WordPress
cd /var/www/sites/${SITE_URL}/html
wp core install --admin_user=${WP_ADMIN_USERNAME} --admin_password=${WP_ADMIN_PASSWORD} --admin_email=${WP_ADMIN_EMAIL} --url=https://${SITE_URL} --title='New Site' --skip-email --allow-root

# WP-CLI Install Plugins
wp plugin install autodescription --allow-root
wp plugin install cloudflare --allow-root
wp plugin install flush-opcache --allow-root
wp plugin install nginx-helper --allow-root
#wp plugin install opcache-manager --allow-root
wp plugin install redis-cache --allow-root
wp plugin install wp-mail-smtp --allow-root

# WP-CLI Activate Plugins
wp plugin activate cloudflare --allow-root
wp plugin activate flush-opcache --allow-root
wp plugin activate nginx-helper --allow-root
#wp plugin activate opcache-manager --allow-root
wp plugin activate redis-cache --allow-root
wp plugin activate wp-mail-smtp --allow-root

# WP-CLI Enable Plugins
wp redis enable --allow-root

# WP-CLI set permalink structure for FastCGI Cache
wp option get permalink_structure --allow-root
wp option update permalink_structure '/%category%/%postname%/' --allow-root

# Setting Permissions Again
# For whatever reason, using WP-CLI to install plugins with --allow-root reassigns
# the ownership of the /uploads, /upgrade, and plugin directories to root:root.
cd /var/www/sites/${SITE_URL}
chown -R www-data:www-data /var/www/sites/${SITE_URL}
chmod +x /var/www/sites/${SITE_URL}/html/wp-cron.php
find . -type d -exec chmod 0755 {} \;
find . -type f -exec chmod 0644 {} \;
chmod 600 /var/www/sites/${SITE_URL}/html/wp-config.php

clear

# Display Plugin Notes
echo "We've downloaded some recommended plugins for you."
echo ""
echo "${BOLD}Downloaded:${NORMAL}"
echo "  - Cloudflare"
echo "  - Nginx Helper"
echo "  - OPcache Manager"
echo "  - Redis Object Cache"
echo "  - The SEO Framework"
echo "  - WP Mail SMTP by WPForms"
echo "  - WP OPcache"
echo ""
echo "------------------------------------------------------------------------------"
echo ""
echo "These plugins have been activated. You'll still need to configure them in WordPress."
echo ""
echo "${BOLD}Activated:${NORMAL}"
echo "  - Cloudflare"
echo "  - Nginx Helper"
echo "  - Redis Object Cache"
echo "  - WP Mail SMTP by WPForms"
echo "  - WP Opcache"
echo ""
echo "------------------------------------------------------------------------------"
echo ""
echo "These plugins have been fully enabled. There is no additional configuration needed."
echo ""
echo "${BOLD}Enabled:${NORMAL}"
echo "  - Redis Object Cache"
echo ""

sleep 10

# Backup
echo ""
echo "Backup script will now run for all sites on this server."
echo ""
/usr/local/bin/enginescript/scripts/cron/backups.sh
echo "Backup: Complete"
clear

echo ""
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo "|${BOLD}Backups${NORMAL}:                                             |"
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo "For your records:"
echo "-------------------------------------------------------"
echo ""
echo "${BOLD}URL:${NORMAL}                     ${SITE_URL}"
echo "-----------------"
echo "${BOLD}Database:${NORMAL}                ${DB}"
echo "${BOLD}Site Prefix${NORMAL}              ${PREFIX}"
echo "${BOLD}DB User:${NORMAL}                 ${USR}"
echo "${BOLD}DB Password:${NORMAL}             ${PSWD}"
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo ""
echo "MySQL Root and Domain login credentials backed up to:"
echo "/home/EngineScript/mysql-credentials/${SITE_URL}"
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo ""
echo "Origin Certificate and Private Key have been backed up to:"
echo "/home/EngineScript/site-backups/${SITE_URL}/ssl-keys"
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo ""
echo "Domain Vhost .conf file backed up to:"
echo "/home/EngineScript/site-backups/${SITE_URL}/nginx"
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo ""
echo "WordPress wp-config.php file backed up to:"
echo "/home/EngineScript/site-backups/${SITE_URL}/wp-config"
echo "-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-==-"
echo ""

sleep 5

# Restart Services
/usr/local/bin/enginescript/scripts/functions/alias/alias-restart.sh

echo ""
echo "============================================================="
echo ""
echo "        Domain setup completed."
echo ""
echo "        Your domain should be available now at:"
echo "        https://${SITE_URL}"
echo ""
echo "        Returning to main menu in 5 seconds."
echo ""
echo "============================================================="
echo ""

sleep 5
