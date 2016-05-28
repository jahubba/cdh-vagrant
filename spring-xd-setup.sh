#!/usr/bin/env bash

echo "[local-source]
name=Local Repo
baseurl=http://u060bdsa13a.kroger.com/repo/
enabled=1
gpgcheck=0
proxy=_none_" > /etc/yum.repos.d/local-source.repo

yum install -y rabbitmq-server
yum install -y spring-xd
yum install -y mariadb-server
yum install -y java-1.8.0-openjdk
yum install -y java-1.8.0-openjdk-devel

rm -f /opt/pivotal/spring-xd/xd/lib/parquet-*
rm -f /opt/pivotal/spring-xd/xd/lib/spark-*
patch -s -p0 < /tmp/xd.patch

#sed -i 's/CONT_INST=2/export CONT_INST=2/g' /etc/init.d/spring-xd-container
echo "
export JAVA_HOME=\"/usr/lib/jvm/java-1.8.0/\"
export XD_CONFIG_LOCATION=file:/opt/sds/config
export XD_MODULE_CONFIG_LOCATION=\${XD_CONFIG_LOCATION}/modules/
export HADOOP_DISTRO=cdh5
export XD_TRANSPORT=rabbit
export SPRING_PROFILES_ACTIVE=\"local,\$(hostname -s)\"" >> /etc/sysconfig/spring-xd

mkdir -p /home/spring-xd/.ssh
cp /tmp/id_rsa* /home/spring-xd/.ssh
chown -R spring-xd:pivotal /home/spring-xd
chmod 700 /home/spring-xd
chmod 600 /home/spring-xd/.ssh/id_rsa

service rabbitmq-server start
service mariadb start
chkconfig rabbitmq-server on
systemctl enable mariadb

rabbitmqctl add_user springxd schwartz
rabbitmqctl add_vhost /spring-xd
rabbitmqctl set_permissions -p /spring-xd springxd ".*" ".*" ".*"
rabbitmqctl add_user admin schwartz
rabbitmqctl set_permissions -p /spring-xd admin ".*" ".*" ".*"
rabbitmqctl set_user_tags admin administrator
rabbitmq-plugins enable rabbitmq_management

service rabbitmq-server restart

mysql <<SQL
CREATE DATABASE IF NOT EXISTS springxd;
GRANT ALL ON springxd.* TO 'springxd'@'%' IDENTIFIED BY 'schwartz';
GRANT ALL ON springxd.* TO 'springxd'@'localhost' IDENTIFIED BY 'schwartz';
FLUSH PRIVILEGES;
SQL

sudo -u hdfs hadoop fs -mkdir /user/spring-xd
sudo -u hdfs hadoop fs -chown spring-xd:pivotal /user/spring-xd
sudo -u hdfs hadoop fs -mkdir -p /apps/xd/modules
sudo -u hdfs hadoop fs -chown -R spring-xd:pivotal /apps/xd
sudo -u hdfs hadoop fs -mkdir -p /data
sudo -u hdfs hadoop fs -chown -R spring-xd:pivotal /data
sudo -u hdfs hadoop fs -mkdir -p /metadata
sudo -u hdfs hadoop fs -chown -R spring-xd:pivotal /metadata
sudo -u hdfs hadoop fs -mkdir -p /staging
sudo -u hdfs hadoop fs -chown -R spring-xd:pivotal /staging

ln -s /opt/workspace/spring-xd-ext/build/tmp/modules /opt/spring-modules
ln -s /opt/workspace/spring-xd-ext/static /opt/sds
alternatives --install /usr/bin xd-shell /opt/pivotal/spring-xd/shell/bin/xd-shell 90
