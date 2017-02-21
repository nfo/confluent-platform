#!/usr/bin/env bash

docker run --name confluent-platform -p 2181:2181 -p 8081:8081 -p 9092:9092 truffade/confluent-platform:3.1.2
