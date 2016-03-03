#!/usr/bin/env bash

echo "Installing..."
apt-get update

#APACHE2
apt-get install -y apache2
echo "ServerName localhost" >> /etc/apache2/httpd.conf

#PHP
apt-get install -y mysql-server mysql-client apache2 php5 php5-cli libapache2-mod-php5 php5-mysql php5-curl php5-gd php-pear php5-imagick php5-mcrypt php5-memcache php5-mhash php5-sqlite php5-xmlrpc php5-xsl php5-json php5-dev libpcre3-dev

#MySQL
apt-get install -y curl
#apt-get install -y phpmyadmin
#Git
apt-get install -y git
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

echo "Please enter the MYSQL root Password: "
read mySQLroot
echo "Creating user for Laravel"
echo "Please enter the new MYSQL Username: "
read mySQLuser
echo "Please enter the password for the new User: "
read mySQLpass
echo "Please enter the new MYSQL Database name: "
read mySQLDB
#Create Database

MYSQL=`which mysql`


Q1="CREATE DATABASE IF NOT EXISTS $mySQLDB;"
Q2="GRANT ALL ON *.* TO '$mySQLuser'@'localhost' IDENTIFIED BY '$mySQLpass';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
#echo "$SQL"
$MYSQL -uroot -p"$mySQLroot" -e "$SQL"

cd /etc/apache2/sites-available

echo "<VirtualHost *:80>" > laravel.conf
echo "DocumentRoot \"/var/www/html/ESP8266WEather/public\"" >> laravel.conf
echo " <Directory \"/var/www/html/ESP8266WEather/public\">" >> laravel.conf
echo "AllowOverride all" >> laravel.conf
echo "</Directory>" >> laravel.conf
echo "</VirtualHost>" >> laravel.conf

cd ../sites-enabled
rm -rf *
ln -s ../sites-available/laravel.conf
sudo a2enmod rewrite 2>&1 >/dev/null
sudo service apache2 restart 2>&1 >/dev/null

mkdir -p /var/www/html
cd /var/www/html

#get Laravel Project
git clone https://gitlab.htl-villach.at/aschrett/ESP8266WEather.git

cd ESP8266WEather

echo "APP_ENV=production" > .env
echo "APP_KEY=SuperRandomString" >> .env
echo "" >> .env
echo "DB_HOST=localhost" >> .env
echo "DB_DATABASE=$mySQLDB" >> .env
echo "DB_USERNAME=$mySQLuser" >> .env
echo "DB_PASSWORD=$mySQLpass" >> .env
echo "" >> .env
echo "CACHE_DRIVER=file" >> .env
echo "SESSION_DRIVER=file" >> .env
echo "QUEUE_DRIVER=sync" >> .env
echo "" >> .env
echo "REDIS_HOST=localhost" >> .env
echo "REDIS_PASSWORD=null" >> .env
echo "REDIS_PORT=6379" >> .env
echo "" >> .env
echo "MAIL_DRIVER=smtp" >> .env
echo "MAIL_HOST=mailtrap.io" >> .env
echo "MAIL_PORT=2525" >> .env
echo "MAIL_USERNAME=null" >> .env
echo "MAIL_PASSWORD=null" >> .env
echo "MAIL_ENCRYPTION=null" >> .env
chown -R www-data:www-data ../ESP8266WEather
#Install Cronjob
crontab -l | { cat; echo "* * * * * php /var/www/html/ESP8266WEather/artisan schedule:run >> /dev/null 2>&1"; } | crontab -


curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

composer install
chown -R www-data:www-data ../ESP8266WEather

php artisan key:generate
php artisan migrate --env local -n
php artisan db:seed --env local -n
php artisan data:fakelastxdays -q
php artisan data:accumulate -q
php artisan data:clean -q
echo "done"
