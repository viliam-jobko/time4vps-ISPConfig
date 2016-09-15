#!/bin/bash

# check root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "# Based on https://www.howtoforge.com/tutorial/perfect-server-ubuntu-16.04-with-apache-php-myqsl-pureftpd-bind-postfix-doveot-and-ispconfig/"
echo "We are going to install Apache, PHP, MySQL and PureFTPd. All configurations will be WIPED!"
echo "ON YOUR OWN RISK!"
read -n 1 -s

# purge preinstalled packages
apt purge -y apache* bind9* postfix

# update and upgrade packages
apt update
apt upgrade -y

# install basic untilities
apt install -y nano mc git screen bash-completion htop iftop openssl
echo 'hardstatus alwayslastline "%{= kw}%-Lw%{= yk}%50>%n%f* %t%{-}%+Lw%<"' > ~/.screenrc
echo 'defshell -bash' >> ~/.screenrc

# set dash
echo "Select NO on next screen to not use dash as default shell"
read -n 1 -s
dpkg-reconfigure dash

# ntp time update
apt -y install ntp ntpdate

# install mysql
apt -y install mysql-server mysql-client
# open mysql to the world
perl -pi -e 's/bind-address/#bind-address/g' /etc/mysql/mysql.conf.d/mysqld.cnf
echo "" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "# ISPConfig require this" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo 'sql-mode="NO_ENGINE_SUBSTITUTION"' >> /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart

# install apache and php
apt -y install apache2 apache2-doc apache2-utils libapache2-mod-php php7.0 php7.0-common php7.0-gd php7.0-mysql php7.0-imap php7.0-cli php7.0-cgi libapache2-mod-fcgid apache2-suexec-pristine php-pear php-auth php7.0-mcrypt mcrypt imagemagick libruby libapache2-mod-python php7.0-curl php7.0-intl php7.0-pspell php7.0-recode php7.0-sqlite3 php7.0-tidy php7.0-xmlrpc php7.0-xsl memcached php-memcache php-imagick php-gettext php7.0-zip
# enable apache modules
a2enmod suexec rewrite ssl actions include cgi httpoxy
service apache2 restart

# install PhpMyAdmin
echo "Configure phpMyAdmin on next screen: Select apache2 with [space] then press [enter]. Later set Yes to configure phpMyAdmin."
read -n 1 -s
apt -y install phpmyadmin

# install OPCode
apt -y install php7.0-opcache php-apcu
service apache2 restart

# install PHP-FPM
apt -y install libapache2-mod-fastcgi php7.0-fpm
a2enmod actions fastcgi alias
service apache2 restart

# install hip hop virtual machine
apt -y install hhvm

# install let's encrypt
mkdir /opt/certbot
cd /opt/certbot
wget https://dl.eff.org/certbot-auto
chmod a+x ./certbot-auto
echo "Installing certbot-auto. Select Yes to install depencendies then NO on next screen to not generate certificates now."
read -n 1 -s
./certbot-auto

# install PureFTPd
apt -y install pure-ftpd-common pure-ftpd-mysql
# chroot users
perl -pi -e 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/g' /etc/default/pure-ftpd-common
service pure-ftpd-mysql restart

# install vlogger
apt -y install vlogger

# download and install latest ISPConfig 3.1
cd /tmp
wget -O ispconfig.tar.gz https://git.ispconfig.org/ispconfig/ispconfig3/repository/archive.tar.gz?ref=stable-3.1
tar xfz ispconfig.tar.gz
cd ispconfig3*/install/
echo "Starting ISPConfig installation"
read -n 1 -s
php -q install.php
