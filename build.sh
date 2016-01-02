#!/usr/bin/env bash

docker build -t socialorra/confluent-platform:2.0.0  .
docker build -t socialorra/confluent-platform:latest .

