#!/bin/bash

mkdir /logs &> /dev/null

cd /confluent-3.0.0

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

sch_reg_cfg=./etc/schema-registry/schema-registry.properties
sch_reg_cfg_tpl=./etc/schema-registry/schema-registry.properties.tpl

if [ ! -f "$sch_reg_cfg_tpl" ]; then
	cp $sch_reg_cfg $sch_reg_cfg_tpl
fi

rp_cfg=./etc/kafka-rest/kafka-rest.properties
rp_cfg_tpl=./etc/kafka-rest/kafka-rest.properties.tpl

if [ ! -f "$rp_cfg_tpl" ]; then
	cp $rp_cfg $rp_reg_cfg_tpl
fi

cat $kafka_cfg_tpl | sed \
	-e "s|zookeeper.connect=localhost:2181|zookeeper.connect=${KAFKA_ADVERTISED_HOST_NAME:-$_IP}:2181|g" \
	-e "s|#listeners=PLAINTEXT://:9092|listeners=PLAINTEXT://0.0.0.0:9092|g" \
	-e "s|#advertised.listeners=PLAINTEXT://your.host.name:9092|advertised.listeners=PLAINTEXT://${KAFKA_ADVERTISED_HOST_NAME:-$_IP}:9092|g" \
	-e "s|zookeeper.connect=localhost:2181|zookeeper.connect=${KAFKA_ADVERTISED_HOST_NAME:-$_IP}:2181|g" \
	-e "s|log.dirs=/tmp/kafka-logs|log.dirs=${KAFKA_DATA_DIR:-$_KAFKA_DATA_DIR}|g" \
	> $kafka_cfg

cat $zk_cfg_tpl | sed \
	-e "s|dataDir=/tmp/zookeeper|dataDir=${ZK_DATA_DIR:-$_ZK_DATA_DIR}|g" \
	> $zk_cfg

cat $sch_reg_cfg_tpl | sed \
	-e "s|kafkastore.connection.url=localhost:2181|kafkastore.connection.url=${KAFKA_ADVERTISED_HOST_NAME:-$_IP}:2181|g" \
	> $sch_reg_cfg

cat $rp_cfg_tpl | sed \
	-e "s|#id=kafka-rest-test-server|id=kafka-rest-proxy|g" \
	-e "s|#schema.registry.url=http://localhost:8081|schema.registry.url=http://${KAFKA_ADVERTISED_HOST_NAME:-$_IP}:8081|g" \
	-e "s|#zookeeper.connect=localhost:2181|zookeeper.connect=http://${KAFKA_ADVERTISED_HOST_NAME:-$_IP}:2181|g" \
	> $rp_cfg

./bin/zookeeper-server-start ./etc/kafka/zookeeper.properties | tee /logs/zookeeper.log &
sleep 5

./bin/kafka-server-start ./etc/kafka/server.properties | tee /logs/kafka.log &
sleep 1

echo "Waiting for Kafka to start..."
timeout 15 grep -q 'Starting metrics collection from monitored broker' <(tail -F /logs/kafka.log)

if [ "$?" -eq 124 ]; then
	echo "error: could not start Kafka server, check logs." >&2
	exit 1
fi

./bin/schema-registry-start ./etc/schema-registry/schema-registry.properties | tee /logs/schema-registry.log &
sleep 1

./bin/kafka-rest-start ./etc/kafka-rest/kafka-rest.properties | tee /logs/kafka-rest.log &

wait
