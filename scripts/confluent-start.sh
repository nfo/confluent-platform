#!/usr/bin/env bash

pushd /confluent-2.0.0

./bin/zookeeper-server-start ./etc/kafka/zookeeper.properties &
sleep 5
./bin/kafka-server-start ./etc/kafka/server.properties &
sleep 5
./bin/schema-registry-start ./etc/schema-registry/schema-registry.properties &

wait

popd

