#!/bin/bash

#yum update -y

# iptables
iptables -F
service iptables stop
chkconfig iptables off

# optional
yum install -y vim

# install require packages for git
yum install -y git

# install require packages for redmine
rpm -Uvh /vagrant/vagrant_resources/epel-release-6-8.noarch.rpm

yum groupinstall "Development Tools"
yum install -y openssl-devel readline-devel zlib-devel curl-devel libyaml-devel
yum install -y mysql-server mysql-devel
yum install -y httpd httpd-devel
yum install -y ImageMagick ImageMagick-devel ipa-pgothic-fonts
yum install -y gcc gcc-c++

cp /vagrant/vagrant_resources/ruby-2.0.0-p481.tar.gz .
tar zxvf ruby-2.0.0-p481.tar.gz
cd ruby-2.0.0-p481
./configure --disable-install-doc
make
make install
cd ..

gem install bundler --no-rdoc --no-ri
yum install -y rubygem-nokogiri

cp /vagrant/vagrant_resources/redmine-2.5.2.tar.gz .
tar zxvf redmine-2.5.2.tar.gz
mv redmine-2.5.2 /var/lib/redmine

# Copy config files
cp -f /vagrant/vagrant_resources/selinux_config /etc/selinux/config
cp -f /vagrant/vagrant_resources/my.cnf /etc/my.cnf
cp -f /vagrant/vagrant_resources/database.yml /var/lib/redmine/config/database.yml
cp -f /vagrant/vagrant_resources/httpd.conf /etc/httpd/conf/httpd.conf
cp -f /vagrant/vagrant_resources/passenger.conf /etc/httpd/conf.d/passenger.conf

# mysql initialize
service mysqld start
chkconfig mysqld on
MYSQL_ROOT_PASSWORD='vagrant'
MYSQL_RM_PASSWORD='rm_pass'
/usr/bin/mysqladmin -u root password "${MYSQL_ROOT_PASSWORD}"
/usr/bin/mysqladmin -u root -h localhost -p${MYSQL_ROOT_PASSWORD} password "${MYSQL_ROOT_PASSWORD}"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e ";CREATE DATABASE db_redmine DEFAULT CHARACTER SET UTF8;GRANT ALL ON db_redmine.* TO user_redmine@localhost IDENTIFIED BY '${MYSQL_RM_PASSWORD}';GRANT ALL ON db_redmine.* TO user_redmine@'%' IDENTIFIED BY '${MYSQL_RM_PASSWORD}'"

cd /var/lib/redmine
bundle install --without development test
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate

# install require packages for passenger
gem install passenger --no-rdoc --no-ri
passenger-install-apache2-module -a

# apache initialize
service httpd start
chkconfig httpd on
chown -R apache:apache /var/lib/redmine

echo 'complete provisioning!'