# Logstash configuration

Logstash configuration for the sample Kibana dashboards consists of a single pipeline configuration (`.conf`) file supplied in the `/logstash/pipeline` directory.

## Pipeline configuration

### Input

The input section configures Logstash to listen for JSON Lines over TCP.

The config assumes unsecure TCP: no Transport Layer Security (SSL/TLS).

#### Alternative input: Apache Kafka

If you have configured OMEGAMON to publish attributes in JSON format to Apache Kafka, then you can use the Kafka input plugin for Logstash to subscribe to that topic (or, depending on your configuration: topics, plural).

Here is a rudimentary Logstash input for Kafka:

```ruby
kafka {
   id => "omegamon_kafka_input"
   bootstrap_servers => "kafkaserver.example.com:9092"
   topics => ["omegamon_json"]
   codec => json
}
```

### Filter

The filter section consists of a `date` option that uses the `write_time` field to set the `@timestamp` field.

The sample Kibana dashboards use the `@timestamp` field as the event time stamp.

### Output

The output section forwards data to the Elasticsearch instance that is running on the same computer as Logstash (`localhost`).

#### `manage_template` does not yet support component templates

As of September 2021, the `manage_template` option of the Elasticsearch output plugin for Logstash supports only *legacy* index templates, not the newer *component* index templates. Until that support is introduced, set `manage_template` to false and use the Elasticsearch API to create a component index template. See the example "create index template" request body in the `/elasticsearch` directory.

For more information, see issue #958, "[Support for new index templates](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues/958)", in GitHub repository `logstash-plugins/logstash-output-elasticsearch`.
