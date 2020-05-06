# kafka-cdc

Resources:

- CDC with MariaDB Maxscale and Kafka: https://mariadb.com/resources/blog/real-time-data-streaming-to-kafka-with-maxscale-cdc/
- CDC from PostresSql to Redshift using Kafka and wal2json (link below): https://www.simple.com/blog/a-change-data-capture-pipeline-from-postgresql-to-kafka
- Plugin for DB changes decoding: https://github.com/eulerto/wal2json
- Kafka Connect and Debezium: https://medium.com/@ankulwarganesh10/streaming-sql-server-cdc-with-apache-kafka-using-debezium-82d89aafb885
- Deploy kafka in Docker: https://docs.confluent.io/5.0.0/installation/docker/docs/installation/connect-avro-jdbc.html
- More Debezium Kafka Docker setup guides: https://info.crunchydata.com/blog/postgresql-change-data-capture-with-debezium

Proposed Steps:
- Setup source DB
- Setup desintation DB / warehouse
- Decide on middle steps above and split workload
- Implement initial deployment files
- Create bash scripts for deployment of services (within Docker if that's in scope)
- Consider whether project will be locally run, Dockerized, or further deployed (is that out of scope?)