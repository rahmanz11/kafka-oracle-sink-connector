##STEP-1:
create table using db_queries.sql

## STEP-2:
Download Confluent JDBC connector from here:
https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-jdbc/versions/10.6.0/confluentinc-kafka-connect-jdbc-10.6.0.zip
Extract the zip at a location, i.e: /home/test/confluent-jdbc-connector

## STEP-3:
Open the worker file, i.e: ./confluent-7.3.1/etc/schema-registry/connect-avro-standalone.properties
replace the `plugin.path` with the location of the connector extracted above, i.e: /home/test/confluent-jdbc-connector
Set the following properties as below in the same file:

key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=false
value.converter.schemas.enable=true

## STEP-4:
Open the `connector.properties` and update the information according to your environment

## STEP-5:
Execute the command where provide the location of the worker file and the connector file accordingly, i.e:
./confluent-7.3.1/bin/connect-standalone ./confluent-7.3.1/etc/schema-registry/connect-avro-standalone.properties /home/test/connector.properties

## STEP-6:
Start producing data to kafka. To produce data from console and test, try the followings:
./confluent-7.3.1/bin/kafka-console-producer --broker-list localhost:9092 --topic books
Then at the producer console, paste the following and hit ENTER to produce a data to the kafka:
`{"schema": {"type": "struct","fields": [{"type": "int64","optional": false,"field": "id"}, {"type": "string","optional": true,"field": "title"}],"optional": false,"name": "foobar"},"payload": {"id": 1,"title": "bar"}}`

## STEP-7:
Execute the following query at database to confirm the insertion of the data:

SQL> select * from books;
ID  TITLE
--- -----
1	bar

## Register schema

# Run schema registry
./bin/schema-registry-start ./etc/schema-registry/schema-registry.properties

curl -s -H 'Content-Type: application/vnd.schemaregistry.v1+json' -H 'Accept: application/vnd.schemaregistry.v1+json' -X POST -d @schema.avsc http://localhost:8081/subjects/books-value/versions

# Run the connector
./confluent-7.3.1/bin/connect-standalone ./confluent-7.3.1/etc/kafka/connect-standalone.properties config.properties

# Produce data
./confluent-7.3.1/bin/kafka-avro-console-producer --broker-list localhost:9092 --topic books --property schema.registry.url=http://localhost:8081 --property value.schema.id=1

{"id": 1,"title": "bar"}

# ./confluent-7.3.1/etc/kafka/connect-standalone.properties
bootstrap.servers=localhost:9092
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=io.confluent.connect.avro.AvroConverter
key.converter.schemas.enable=false
value.converter.schemas.enable=true
value.converter.schema.registry.url=http://localhost:8081
offset.storage.file.filename=/tmp/connect.offsets
offset.flush.interval.ms=10000
plugin.path=/home/admin/confluent_plugins

# connector.properties
name=oracle_sink_test
connector.class=io.confluent.connect.jdbc.JdbcSinkConnector
connection.url=jdbc:oracle:thin:@db_host:db_port/db_sid_or_service
connection.user=db_user
connection.password=db_password
topics=books
tasks.max=1
table.name.format=BOOKS
auto.create=false
schemas.enable=true
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.schema.registry.url=http://localhost:8081
insert.mode=upsert
pk.mode=record_value
pk.fields=ID
transforms=renameFields
transforms.renameFields.type=org.apache.kafka.connect.transforms.ReplaceField$Value
transforms.renameFields.renames=id:ID,title:TITLE
transforms.selectFields.whitelist=ID,TITLE