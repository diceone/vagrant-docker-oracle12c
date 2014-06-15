#!/bin/sh

# convert into Oracle Linux 6
curl -O https://linux.oracle.com/switch/centos2ol.sh
sh centos2ol.sh
yum upgrade -y

# fix locale warning
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

# install Oracle Database prereq packages
yum install -y oracle-rdbms-server-12cR1-preinstall

# install Docker
rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum update -y
yum install -y lxc-docker
service docker start
chkconfig docker on

# install UEK kernel
yum install -y kernel-uek-devel
grubby --set-default=/boot/vmlinuz-2.6.39*

# confirm
cat /etc/oracle-release
