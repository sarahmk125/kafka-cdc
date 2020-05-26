Run in local terminal (or whereever you are hosting docker containers) 

https://info.crunchydata.com/blog/postgresql-change-data-capture-with-debezium

### Initiate Zookeeper ## 
First we need to start zookeeper which is a distributed configuration store. Kafka uses this to keep information about which Kafka node is the controller, it also stores the configuration for topics. This is where the status of what data has been read is stored so that if we stop and start we don’t lose any data.

```
docker run -it --rm --name zookeeper -p 2181:2181 -p 2888:2888 -p 3888:3888 debezium/zookeeper:0.10
```
### Open Kafka ### 
```
docker run -it --rm --name kafka -p 9092:9092 --link zookeeper:zookeeper debezium/kafka:0.10
```

## Create mock Postgres DB ##

### Connect to Cruncy Containers Git and edit a few config files ### 
https://github.com/CrunchyData/crunchy-containers
```
#we will need to customize the postgresql.conf file to ensure wal_level=logical
cat << EOF > pgconf/postgresql.conf
# here are some sane defaults given we will be unable to use the container
# variables
# general connection
listen_addresses = '*'
port = 5432
max_connections = 20
# memory
shared_buffers = 128MB
temp_buffers = 8MB
work_mem = 4MB
# WAL / replication
wal_level = logical
max_wal_senders = 3
# these shared libraries are available in the Crunchy PostgreSQL container
shared_preload_libraries = 'pgaudit.so,pg_stat_statements.so'
EOF
```

```
# setup the environment file to build the container. 
# we don't really need the PG_USER as we will use the postgres user for replication
# some of these are not needed based on the custom configuration
cat << EOF > pg-env.list
PG_MODE=primary
PG_PRIMARY_PORT=5432
PG_PRIMARY_USER=postgres
PG_DATABASE=testdb
PG_PRIMARY_PASSWORD=debezium
PG_PASSWORD=not
PG_ROOT_PASSWORD=matter
PG_USER=debezium
EOF
```
### Run Container ### 
** note - change location of crunchy-container git folder **
```
docker run -it --rm --name=pgsql --env-file=pg-env.list --volume=/Users/samuelchapman/Desktop/Northwestern/Capstone/final/github/crunchy-containers/pgconf:/pgconf -d crunchydata/crunchy-postgres:centos7-11.4-2.4.1
```

### Connect to Postgres ###
 Attach a console to the pgsql container using the label to reference the running container.
```
docker exec -it pgsql /bin/bash
su postgres
psql postgres
```
Add some data 

```
CREATE TABLE customers (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text);
ALTER TABLE customers REPLICA IDENTITY USING INDEX customers_pkey;
INSERT INTO customers (name) VALUES ('joe'), ('bob'), ('sue');
```
Create DB to send changes too
```
CREATE DATABASE customers;
```
### Connector Image ### 
Now we can bring up the connector image, however we will have to make sure the jdbc-sink jar is in the connector image. A simple way to do this is to use the Debezium end to end JDBC example found here https://github.com/debezium/debezium-examples/tree/master/end-to-end-demo/debezium-jdbc
From this directory run docker build .   The output from this will be successfully built 62b583dce71b where the hash code at the end will be unique to your environment

Once the container is built you can run it using the following. Note the use of the hash. We could have tagged it using
```
docker tag <REPLACE ME WITH HASH> jdbc-sink
```
Then use the name in the following 
```
docker run -it --rm --name connect -p 8083:8083 -e GROUP_ID=1 -e CONFIG_STORAGE_TOPIC=my_connect_configs -e OFFSET_STORAGE_TOPIC=my_connect_offsets -e STATUS_STORAGE_TOPIC=my_connect_statuses --link zookeeper:zookeeper --link kafka:kafka --link pgsql:pgsql <REPLACE ME WITH HASH>
```

Kafka connect has a REST endpoint which we can use to find out things like what connectors are enabled in the container.
```
curl -H "Accept:application/json" localhost:8083/connectors/
```

### Create a Source Connector ### 

1) We require a bit of JSON to send to the REST API to configure the source connector - create postgresql-connect.json
```
{
  "name": "inventory-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "pgsql",
    "plugin.name": "pgoutput",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "debezium",
    "database.dbname" : "postgres",
    "database.server.name": "fullfillment",
    "table.whitelist": "public.customers"
  }
}
```
2) run 
```
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d @postgresql-connect.json
```
3) create jdbc-sink.json to configure sink connector
```
{
  "name": "jdbc-sink",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "topics": "fullfillment.public.customers",
    "dialect.name": "PostgreSqlDatabaseDialect",
    "table.name.format": "customers",
    "connection.url": "jdbc:postgresql://pgsql:5432/customers?user=postgres&password=debezium",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "false",
    "auto.create": "true",
    "insert.mode": "upsert",
    "pk.fields": "id",
    "pk.mode": "record_key",
    "delete.enabled": "true"
  }
}
```
Note: Kafka JDBC sink defaults to creating the destination table with the same name as the topic which in this case is fullfillment.public.customers I’m not sure of other databases but in PostgreSQL this creates a table which needs to be double quoted to use. I tend to avoid these so I added the "table.name.format": "customers" to force it to create a table named customers.

4) enable sink connector 

```
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d @jdbc-sink.json
```

You now have a two postgres databases, "postgres" and "customers", where customers is a replica of the postgres db.  
