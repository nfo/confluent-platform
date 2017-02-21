#!/bin/bash
set -xe

mkdir -p /logs

cd /confluent-3.1.2

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

# configure kafka
kafka_cfg=./etc/kafka/server.properties
if [ -n "$KAFKA_ADVERTISED_LISTENERS" ]; then
  sed -e "s|#listeners=PLAINTEXT://:9092|listeners=PLAINTEXT://0.0.0.0:9092|g" -i $kafka_cfg
  sed -e "s|#advertised.listeners=PLAINTEXT://your.host.name:9092|advertised.listeners=PLAINTEXT://$KAFKA_ADVERTISED_LISTENERS:9092|g" -i $kafka_cfg
else
  sed -e "s|#listeners=PLAINTEXT://:9092|listeners=PLAINTEXT://0.0.0.0:9092|g" -i $kafka_cfg
  sed -e "s|#advertised.listeners=PLAINTEXT://your.host.name:9092|advertised.listeners=PLAINTEXT://0.0.0.0:9092|g" -i $kafka_cfg
fi
sed -e "s|log.dirs=/tmp/kafka-logs|log.dirs=/kafka-logs|g" -i $kafka_cfg

echo
echo "=============== $kafka_cfg ==============="
echo
cat $kafka_cfg
echo
echo "==============="
echo

# configure zookeeper
zk_cfg=./etc/kafka/zookeeper.properties
sed -e "s|dataDir=/tmp/zookeeper|dataDir=/zookeeper|g" -i $zk_cfg

echo
echo "=============== $zk_cfg ==============="
echo
cat $zk_cfg
echo
echo "==============="
echo

./bin/zookeeper-server-start ./etc/kafka/zookeeper.properties | tee /logs/zookeeper.log &
waitForZookeeper

./bin/kafka-server-start ./etc/kafka/server.properties | tee /logs/kafka.log &
waitForKafka

./bin/schema-registry-start ./etc/schema-registry/schema-registry.properties | tee /logs/schema-registry.log &
waitForPort localhost 8081

wait
