#!/bin/sh

####################
# params
####################
MY_HOME="/home/vagrant"
TMP_DIR="${MY_HOME}/tmp"

####################
# file download
####################
mkdir -p ${TMP_DIR}
cd ${TMP_DIR}
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/.bashrc
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/resolv.conf
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/epel.repo
#wget https://dl.dropboxusercontent.com/u/8710420/vagrant/httpd.conf
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/ntp.conf
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/my.cnf
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/configuration.yml
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/database.yml
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/sql_redmine.sql
wget https://dl.dropboxusercontent.com/u/8710420/vagrant/passenger.conf

####################
# update
####################
#yum -y update

####################
# resolv.conf
####################
mv /etc/resolv.conf /etc/resolv.conf.org
cp -af ${TMP_DIR}/resolv.conf /etc/

####################
# iptables off
####################
/sbin/iptables -F
/sbin/service iptables stop
/sbin/chkconfig iptables off

####################
# epel, remi
####################
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
rpm -Uvh remi-release-6.rpm
cp -af ${TMP_DIR}/epel.repo /etc/yum.repos.d/epel.repo

#####################
## ntp
#####################
#yum -y install ntp
#mv /etc/ntp.conf /etc/ntp.conf.org
#cp -af ${TMP_DIR}/ntp.conf /etc/
#/sbin/service ntpd start
#/sbin/chkconfig ntpd on

####################
# dev tools
####################
yum groupinstall "Development Tools"

####################
# apps install
#   MySQL, Apache, ImageMagick, JapaneseFont, Vim
####################
yum -y install openssl-devel readline-devel zlib-devel curl-devel libyaml-devel
yum -y install mysql-server mysql-devel
yum -y install httpd httpd-devel
yum -y install ImageMagick ImageMagick-devel ipa-pgothic-fonts
yum -y install vim-enhanced

####################
# Apache
####################
cp -af /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.org
cp -af ${TMP_DIR}/passenger.conf /etc/httpd/conf.d/
#service httpd start
#chkconfig httpd on

####################
# MySQL
####################
mv -f /etc/my.cnf /etc/my.cnf.org
cp -af ${TMP_DIR}/my.cnf /etc/
/sbin/service mysqld start
/sbin/chkconfig mysqld on

####################
# create database
####################
mysql -u root < sql_redmine.sql

####################
# Ruby
####################
curl -O http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p451.tar.gz
tar zxvf ruby-2.0.0-p451.tar.gz 
cd ruby-2.0.0-p451
./configure --disable-install-doc
make
make install
cd ..
#echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source ~/.bash_profile

####################
# gem packages
####################
#gem install json -v '1.8.1'
gem install bundler --no-rdoc --no-ri

####################
# Redmine
####################
curl -O http://www.redmine.org/releases/redmine-2.5.0.tar.gz
tar xvf redmine-2.5.0.tar.gz
mv -f redmine-2.5.0 /var/lib/redmine
cp -af ${TMP_DIR}/database.yml /var/lib/redmine/config/
chown -R apache:apache /var/lib/redmine

####################
# bundle
####################
cd /var/lib/redmine
bundle install --without development test

####################
# Redmine configuration
####################
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate

####################
# Passenger
####################
gem install passenger --no-rdoc --no-ri
#passenger-install-apache2-module

####################
# cleanup
####################
cd ${MY_HOME}
rm -rf ${TMP_DIR}
