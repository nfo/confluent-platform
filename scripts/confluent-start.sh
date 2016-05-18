#!/bin/bash

mkdir /logs &> /dev/null

cd /confluent-1.0.1

_IP=$(hostname -i | awk '{print $1}')

_KAFKA_DATA_DIR=/kafka-logs

_ZK_DATA_DIR=/zookeeper

kafka_cfg=./etc/kafka/server.properties
kafka_cfg_tpl=./etc/kafka/server.properties.tpl

if [ ! -f "$kafka_cfg_tpl" ]; then
	cp $kafka_cfg $kafka_cfg_tpl
fi

zk_cfg=./etc/kafka/zookeeper.properties
zk_cfg_tpl=./etc/kafka/zookeeper.properties.tpl

if [ ! -f "$zk_cfg_tpl" ]; then
	cp $zk_cfg $zk_cfg_tpl
fi

cat $kafka_cfg_tpl | sed \
	-e "s|#advertised.host.name=<hostname routable by clients>|advertised.host.name=${KAFKA_ADVERTISED_HOST_NAME:-$_IP}|g" \
	-e "s|log.dirs=/tmp/kafka-logs|log.dirs=${KAFKA_DATA_DIR:-$_KAFKA_DATA_DIR}|g" \
	> $kafka_cfg

# set kafka logging level to info so we can monitor startup
sed -i 's/WARN/INFO/g' etc/kafka/tools-log4j.properties

cat $zk_cfg_tpl | sed \
	-e "s|dataDir=/tmp/zookeeper|dataDir=${ZK_DATA_DIR:-$_ZK_DATA_DIR}|g" \
	> $zk_cfg

./bin/zookeeper-server-start ./etc/kafka/zookeeper.properties | tee /logs/zookeeper.log &
sleep 5

./bin/kafka-server-start $kafka_cfg | tee /logs/kafka.log &
sleep 1

echo "Waiting for Kafka to start..."
timeout 15 grep -q 'New broker startup callback for' <(tail -F /logs/kafka.log)

if [ "$?" -eq 124 ]; then
	echo "error: could not start Kafka server, check logs." >&2
	exit 1
fi

./bin/schema-registry-start ./etc/schema-registry/schema-registry.properties | tee /logs/schema-registry.log &

wait

