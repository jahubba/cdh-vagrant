#!/usr/bin/env bash

#disable SELINUX
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

sed -i 's/localhost.localdomain//g' /etc/hosts

yum update -y
yum install -y git
yum install -y docker
yum -y groups install "GNOME Desktop"

#Fix hosts
sed -i 's/\(localhost4\|localhost4.localdomain4\)//g' /etc/hosts

swapoff -v /dev/VolGroup00/LogVol01
pvcreate /dev/sdb
vgextend VolGroup00 /dev/sdb
lvextend -l +$(pvdisplay /dev/sdb -c | cut -d: -f10) /dev/VolGroup00/LogVol01
mkswap /dev/VolGroup00/LogVol01
swapon -va
cat /proc/swaps # free
