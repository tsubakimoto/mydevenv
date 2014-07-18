#!/bin/bash

yum update -y

# iptables
iptables -F
service iptables stop
chkconfig iptables off

# optional
yum install -y vim

# install require packages for git
yum install -y git

# download bitnami redmine
wget https://bitnami.com/redirect/to/38030/bitnami-redmine-2.5.2-0-linux-x64-installer.run /home/vagrant/

# Copy config files
cp -f /vagrant/vagrant_resources/selinux_config /etc/selinux/config

echo 'complete provisioning!'