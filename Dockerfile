FROM frolvlad/alpine-oraclejdk8

LABEL version="3.1.2"

RUN apk --update add unzip wget bash coreutils

# packed up into a single RUN (no ADD) command to save space inside the container
RUN wget http://packages.confluent.io/archive/3.1/confluent-oss-3.1.2-2.11.zip && \
    unzip /confluent-oss-3.1.2-2.11.zip -d / && \
    rm -f /confluent-oss-3.1.2-2.11.zip

EXPOSE 9092 2181 8081

COPY scripts/start.sh /

ENTRYPOINT ["/start.sh"]

VOLUME ["/kafka-logs", "/zookeeper", "/logs"]

