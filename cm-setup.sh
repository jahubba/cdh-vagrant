#!/usr/bin/env bash

CDH_PARCEL_VERSION='5.5.1-1.cdh5.5.1.p0.11'
KAFKA_PARCEL_VERSION='0.8.2.0-1.kafka1.4.0.p0.56'
DOWNLOAD_CREATES=/opt/cloudera/parcel-repo/CDH-${CDH_PARCEL_VERSION}-el7.parcel.sha
DISTRIBUTE_CREATES=/opt/cloudera/parcel-cache/CDH-${CDH_PARCEL_VERSION}-el7.parcel
ACTIVATE_CREATES=/opt/cloudera/parcels/CDH

function wait_for_file_to_appear() {
    while [ ! -e $1 ]; do
        sleep 1
    done
}

function wait_for_file_to_disappear() {
    while [ -e $1 ]; do
        sleep 1
    done
}

#fix for cloudera pushing wrong repo
rm /etc/yum.repos.d/cloudera-manager.repo
yum-config-manager --add-repo http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
yum-config-manager --enable cloudera-manager
#fix for cloudera pushing wrong repo
sed -i 's/repos.jenkins.cloudera.com\/cm5.5.0-nightly/archive.cloudera.com\/cm5/g' /etc/yum.repos.d/cloudera-manager.repo
yum install -y cloudera-manager-server
yum install -y cloudera-manager-server-db-2
yum install -y mysql-connector-java
yum install -y oracle-j2sdk1.7
yum install -y mariadb-server

echo "Starting cm services"
service cloudera-scm-server-db start
service cloudera-scm-server start
service mariadb start
chkconfig cloudera-scm-server-db on
chkconfig cloudera-scm-server on
systemctl enable mariadb

echo "Waiting for Cloudera manager"
while ! curl -s http://admin:admin@localhost:7180/api/v9/tools/echo | grep "Hello, World"; do sleep 10; done

#parse proxy
if [ -v http_proxy ] ; then 
  proxy_user=$(echo $http_proxy | sed -r 's/http:\/\/([^:]*):.*@.*/\1/')
  proxy_password=$(echo $http_proxy | sed -r 's/http:\/\/.*:([^@]*)@.*/\1/')
  proxy_host=$(echo $http_proxy | sed -r 's/http:\/\/.*@([^:]*).*/\1/')
  proxy_port=$(echo $http_proxy | sed -r 's/http:\/\/.*@.*:([^\/]*).*/\1/')
  proxy_json=$(paste -s <<PROXY
    {"items":[{"name":"parcel_proxy_server","value":"${proxy_host}"},{"name":"parcel_proxy_port","value":${proxy_port}},
	{"name":"parcel_proxy_user","value":"${proxy_user}"},{"name":"parcel_proxy_password","value":"${proxy_password}"},
	{"name":"phone_home","value":"false"}]},"contentType":"application/json"}]}
PROXY
  )
  curl http://admin:admin@localhost:7180/api/v9/cm/config --data $(echo $proxy_json | tr -d " \t\n\r") --header Content-Type:application/json -X PUT
fi

echo "Setting up Space Balls The Cluster"
curl http://admin:admin@localhost:7180/api/v9/cm/deployment --data @/tmp/eagle5-deployment.json --header Content-Type:application/json -X PUT
curl http://admin:admin@localhost:7180/api/v9/cm/commands/hostInstall --data '{"hostNames":["megamaid"],"userName":"vagrant","password":"vagrant","unlimitedJCE":"true"}' --header Content-Type:application/json
#host=$(curl http://admin:admin@localhost:7180/api/v9/hosts | grep hostId | sed 's/.*hostId" : "\(.*\)".*/\1/g')
#curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/hosts --data "{\"	items\":[{\"hostId\":\"$host\"}]}" --header Content-Type:application/json

echo "Downloading parcels"
if [ ! -e "${DOWNLOAD_CREATES}" ]; then
  curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/parcels/products/CDH/versions/${CDH_PARCEL_VERSION}/commands/startDownload -X POST
  curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/parcels/products/KAFKA/versions/${KAFKA_PARCEL_VERSION}/commands/startDownload -X POST
fi
wait_for_file_to_appear ${DOWNLOAD_CREATES}
sleep 60

echo "Distributing parcles"
if [ ! -e "${DISTRIBUTE_CREATES}" ]; then
  curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/parcels/products/CDH/versions/${CDH_PARCEL_VERSION}/commands/startDistribution -X POST
  curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/parcels/products/KAFKA/versions/${KAFKA_PARCEL_VERSION}/commands/startDistribution -X POST
fi
wait_for_file_to_appear ${DISTRIBUTE_CREATES}
sleep 60
wait_for_file_to_disappear /opt/cloudera/parcel-cache/tmp*

echo "Activating parcles"
if [ ! -e "${ACTIVATES_CREATES}" ]; then
  curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/parcels/products/CDH/versions/${CDH_PARCEL_VERSION}/commands/activate -X POST
  curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/parcels/products/KAFKA/versions/${KAFKA_PARCEL_VERSION}/commands/activate -X POST
fi
wait_for_file_to_appear ${ACTIVATES_CREATES}

mysql <<SQL
CREATE DATABASE IF NOT EXISTS metastore;
GRANT ALL ON metastore.* TO 'hive'@'%' IDENTIFIED BY 'schwartz';
GRANT ALL ON metastore.* TO 'hive'@'localhost' IDENTIFIED BY 'schwartz';
FLUSH PRIVILEGES;
SQL

echo "Starting services"
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/zookeeper/commands/zooKeeperInit -X POST
sleep 60
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/zookeeper/commands/start -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/hdfs/roleCommands/hdfsFormat --data '{"items":["hdfs-NAMENODE"]}' --header Content-Type:application/json
sleep 60
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/hdfs/commands/start -X POST
sleep 60
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/spark_on_yarn/commands/CreateSparkUserDirCommand -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/spark_on_yarn/commands/CreateSparkHistoryDirCommand -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/hdfs/commands/hdfsCreateTmpDir -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/hive/commands/hiveCreateMetastoreDatabaseTables -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/solr/commands/initSolr -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/yarn/commands/yarnCreateJobHistoryDirCommand -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/services/oozie/commands/installOozieShareLib -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/commands/deployClientConfig -X POST
curl http://admin:admin@localhost:7180/api/v9/cm/service/commands/start -X POST
curl http://admin:admin@localhost:7180/api/v9/clusters/spaceballsthecluster/commands/start -X POST
