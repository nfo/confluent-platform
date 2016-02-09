#!/bin/bash

cd /confluent-2.0.0

IP=$(cat /etc/hosts | head -n1 | awk '{print $1}')

kafka_cfg=./etc/kafka/server.properties
kafka_cfg_tpl=./etc/kafka/server.properties.tpl

cp $kafka_cfg $kafka_cfg_tpl

cat $kafka_cfg_tpl | sed \
	-e "s|#advertised.host.name=<hostname routable by clients>|advertised.host.name=${KAFKA_ADVERTISED_HOST_NAME:-$IP}|g" \
	> $kafka_cfg

rm $kafka_cfg_tpl

./bin/zookeeper-server-start ./etc/kafka/zookeeper.properties &
sleep 5
./bin/kafka-server-start $kafka_cfg &
sleep 5
./bin/schema-registry-start ./etc/schema-registry/schema-registry.properties &

wait

