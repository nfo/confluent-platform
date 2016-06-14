#!/bin/bash
set -xe

mkdir -p /logs

cd /confluent-3.0.0

_IP=$(hostname -i | awk '{print $1}')

_KAFKA_DATA_DIR=/kafka-logs

_ZK_DATA_DIR=/zookeeper

waitForZookeeper() {
  i="0"
  until [ "$(echo ruok | nc localhost 2181)" = "imok" ]
  do
    if [ $i -eq 50 ]
    then
      echo "zookeeper is not up, giving up..."
      exit -1
    fi
    sleep 2
    i=$[$i+1]
  done
}

waitForKafka() {
	timeout 50 grep -q 'Starting metrics collection from monitored broker' <(tail -F /logs/kafka.log)

	if [ "$?" -eq 124 ]; then
		echo "error: could not start Kafka server, check logs." >&2
		exit 1
	fi
}

waitForPort() {
  i="0"
	host=$1
  port=$2
	wait_interval=${3:-2}
	total_wait=${4:-50}
  while ! nc $host $port < /dev/null
  do
    if [ $i -eq $total_wait ]
    then
      echo "$host is not listening on port $port, giving up..."
      exit -1
    fi
    sleep $wait_interval
    i=$[$i+1]
  done
}

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

rp_cfg=./etc/kafka-rest/kafka-rest.properties
rp_cfg_tpl=./etc/kafka-rest/kafka-rest.properties.tpl

if [ ! -f "$rp_cfg_tpl" ]; then
	cp $rp_cfg $rp_cfg_tpl
fi

cat $kafka_cfg_tpl | sed \
	-e "s|#listeners=PLAINTEXT://:9092|#listeners=PLAINTEXT://0.0.0.0:9092|g" \
	-e "s|log.dirs=/tmp/kafka-logs|log.dirs=${KAFKA_DATA_DIR:-$_KAFKA_DATA_DIR}|g" \
	> $kafka_cfg

cat $zk_cfg_tpl | sed \
	-e "s|dataDir=/tmp/zookeeper|dataDir=${ZK_DATA_DIR:-$_ZK_DATA_DIR}|g" \
	> $zk_cfg

cat $rp_cfg_tpl | sed \
	-e "s|#id=kafka-rest-test-server|id=kafka-rest-proxy|g" \
	-e "s|#schema.registry.url=http://localhost:8081|schema.registry.url=http://localhost:8081|g" \
	-e "s|#zookeeper.connect=localhost:2181|zookeeper.connect=localhost:2181|g" \
	> $rp_cfg

./bin/zookeeper-server-start ./etc/kafka/zookeeper.properties | tee /logs/zookeeper.log &
waitForZookeeper

./bin/kafka-server-start ./etc/kafka/server.properties | tee /logs/kafka.log &
waitForKafka

./bin/schema-registry-start ./etc/schema-registry/schema-registry.properties | tee /logs/schema-registry.log &
waitForPort localhost 8081

./bin/kafka-rest-start ./etc/kafka-rest/kafka-rest.properties | tee /logs/kafka-rest.log &
waitForPort localhost 8082

wait
