
Build :
./build.sh

Run :
docker run -d --name confluent-platform -e KAFKA_ADVERTISED_HOST_NAME=192.168.99.100 -p 2181:2181 -p 8081:8081 -p 8082:8082 -p 9092:9092 gayakwad/confluent-platform
