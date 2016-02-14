Confluent Stream Data Platform on Single Docker Container
=========================================================

Experimental docker image for running the [Confluent Platform](http://confluent.io/docs/current/index.html).
This image is currently intended for development use, not for production use.

[![](https://badge.imagelayers.io/socialorra/confluent-platform:latest.svg)](https://imagelayers.io/?images=socialorra/confluent-platform:latest 'Get your own badge on imagelayers.io')

Volumes
-------

The following volumes are available:
- /kafka-logs: Kafka broker data
- /zookeeper: Zookeeper server data
- /logs: log files

Building Image
---------------

For convenience, a `build.sh` script is provided.

A second script, `push.sh`, will push the generated image to Docker Hub. First you'll need to be logged in:

    docker login --username=yourhubusername --password=yourpassword --email=youremail@company.com

then execute the script.

