# kafka-cdc

## Getting Started

### Tools
- Install Docker [here](https://docs.docker.com/engine/install/)
- Install Docker Compose [here](https://docs.docker.com/compose/install/)

### Starting the Project

- Startup docker and the appropriate containers. Run: `bash startup.sh`
    - Note: There is a pseudo `Dockerfile` that could be a real project, but is just there for show.
    - The docker compose file is referenced here in startup; all the required containers and configurations are setup, using the resources listed below.
- Setup a kafka connector. Run: `bash create_connectors.sh`
    - Note: You may have to wait a minute after running the startup to successfully create the connections.
    - To view connectors: `curl -H "Accept:application/json" localhost:8083/connectors/`
- Test the connector is setup properly:
    - Make changes in the MySQL db to pass some events to the connector.
        - To get to the mysql command client, on the local MySQL container:
            - Exec onto the container. Run: `docker exec -it kafka-cdc_mysql_1 bash`
            - Run commandline mysql for the `inventory` database. Run: `mysql -u mysqluser -p inventory`
                - It will prompt for password. Enter: `mysqlpw`
            - To show tables: `show tables;`
        - Now, make some chages. Example insert: `INSERT INTO customers VALUES (default, "Sarah", "Thompson", "kitt2@acme.com");`
    - View the above changes in the connector by logging the container. Run: `docker logs --tail 1000 -f kafka-cdc_connect_1`
        - Note: the logs above will show scanning of all tables in the inventory connector.
    - Checkout the data on the PostgreSQL db locally to validate the changes
        - To get the pgsql client:
            - Exec onto the container. Run: `docker exec -it kafka-cdc_pgsql_1 bash`
            - RUT RO, THIS FAILS!!!

### Stopping the Project

- Stop all docker containers. Run: `bash down.sh`

## Resources

### Used for Above Implementation

https://debezium.io/documentation/reference/1.1/tutorial.html

https://github.com/debezium/debezium-examples/blob/master/unwrap-smt/docker-compose.yaml

https://info.crunchydata.com/blog/postgresql-change-data-capture-with-debezium

https://github.com/debezium/debezium-examples/tree/master/end-to-end-demo


### Other Resources:

- CDC with MariaDB Maxscale and Kafka: https://mariadb.com/resources/blog/real-time-data-streaming-to-kafka-with-maxscale-cdc/
- CDC from PostresSql to Redshift using Kafka and wal2json (link below): https://www.simple.com/blog/a-change-data-capture-pipeline-from-postgresql-to-kafka
- Plugin for DB changes decoding: https://github.com/eulerto/wal2json
- Kafka Connect and Debezium: https://medium.com/@ankulwarganesh10/streaming-sql-server-cdc-with-apache-kafka-using-debezium-82d89aafb885
- Deploy kafka in Docker: https://docs.confluent.io/5.0.0/installation/docker/docs/installation/connect-avro-jdbc.html
- More Debezium Kafka Docker setup guides: https://info.crunchydata.com/blog/postgresql-change-data-capture-with-debezium

To stop Docker files:
```
docker-compose -f docker-compose-debezium-local.yml stop
```
to remove docker containers:
```
docker-compose -f docker-compose-debezium-local.yml rm
```
