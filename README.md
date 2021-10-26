# Sample Elastic Kibana dashboards for IBM Z OMEGAMON Data Provider

This repository demonstrates visualizing OMEGAMON attributes from IBM Z OMEGAMON Data Provider in Elastic Kibana dashboards.

OMEGAMON includes agents that monitor z/OS systems, database products, and applications. In OMEGAMON terminology, the data that these agents collect, such as CPU usage, are known as *attributes*. In data analytics terminology, OMEGAMON attributes are *metrics*.

You can use this repository to:

-   Build a Docker image and then start a container that runs the Elastic Stack with sample Kibana dashboards and sample data preconfigured
-   Configure your own Elastic Stack instance with the sample Kibana dashboards and sample data
-   Visualize your own data in the sample dashboards

This repository contains:

-   Elastic Stack artifacts:
    -   Kibana saved objects, including dashboards and related objects such as visualizations and index patterns
    -   Logstash pipeline configuration file
    -   Elasticsearch index template and lifecycle policy
-   Sample data in JSON Lines format
-   Source files for a Docker image that configures an Elastic Stack instance with all of the above in a ready-to-use container

## Getting started

To start using the sample dashboards, choose one of the following options:

-   Start a Docker container that runs the Elastic Stack with the dashboards and sample data preconfigured.

    You can immediately start exploring the dashboards with the sample data. The Docker container is also preconfigured to listen for OMEGAMON attributes in JSON Lines format over TCP from IBM Z OMEGAMON Data Provider.

    See the [`docker/README.md`](docker/README.md) file.

-   Configure an existing Elastic Stack instance.

    See the heading "Installing the dashboards in an existing Elastic Stack instance".

## Scope and intended use of these dashboards

The sample dashboards provided in this repository are intended to be useful out-of-the-box. However, they are *not* a fully fledged solution for analyzing OMEGAMON attributes. Instead, these sample dashboards demonstrate some typical use cases for visualizing OMEGAMON attributes.

Each OMEGAMON agent monitors a set of attributes. Related attributes are organized into groups, also known as tables. Each table typically contains a dozen or more attributes. Each agent can collect many tables. In total, across all agents, there are hundreds of attribute tables.

The sample dashboards in this repository visualize data from a small subset of attribute tables collected by a single agent: IBM Z OMEGAMON Monitor for z/OS, 5.6.

The developers of these dashboards anticipate that customers will examine the dashboards, and then copy and adapt selected visualizations into bespoke dashboards to suit their own requirements.

## Requirements

Depending on what you want to do:

-   **You don't need OMEGAMON or a mainframe to use this repository.** You can use the dashboards with the included sample data.
    -   To start a Docker container with the sample data, the only requirement is Docker.

        The Docker image was built and tested using **Docker 20.10.6 on Linux Ubuntu 20.04**.
    -   To install the dashboards in your own instance of Elastic Stack with the sample data, the only requirement is Elastic Stack.

        The Elastic Stack artifacts in this repository were developed and tested with **Elastic Stack 7.14.0**.

        For compatibility with other versions of Elastic Stack, see the Elastic Stack documentation.

-   To visualize your own data, you need a z/OS mainframe with IBM Z OMEGAMON Data Provider configured to forward attributes to Logstash.

    To get IBM Z OMEGAMON Data Provider, contact your IBM Software representative for OMEGAMON products.

### Elastic Stack system requirements

Minimum recommended system requirements for the computer, or Docker container, running Elastic Stack:

-   16 GB RAM
-   200 GB disk space
-   4 vCPUs

Actual system requirements depend on your site-specific practices. For example, the disk space required depends on the amount of data stored in Elasticsearch,
which depends on various site-specific factors, including:

-  How much data you forward: Which attribute tables, and fields in those tables, you forward, and how many z/OS systems you are monitoring
-  How frequently you forward data, controlled by the attribute table collection interval in OMEGAMON
-  How long you keep data, controlled by an Elasticsearch index lifecycle policy

## Repository contents

The following file and directory are relevant only if you are interested in Docker. Otherwise, you can ignore them:

-   `Dockerfile`\
    Contains instructions for building the `z-omegamon-analytics-elastic` Docker image.

-   `docker/`\
    Contains files required by the Docker image.

The remaining directories are relevant whether or not you use Docker:

-   `data/`\
    Contains sample OMEGAMON attribute data in JSON Lines format from IBM Z OMEGAMON Data Provider.

-   `elasticsearch/`\
    Contains an Elasticsearch index template (component, not legacy) and lifecycle policy.

-   `kibana/`\
    Contains Kibana saved objects, including dashboards and related objects such as index patterns.

-   `logstash/`\
    Contains a Logstash pipeline configuration.

The following directory is for use only by the maintainers of this repository:

-  `docs/`\
   Contains files required to build the `README.pdf` file, which offers an alternative presentation format to the `README.md` files in this repository. Depending on how you received the repository, this directory might not be present in your copy.

## Installing the dashboards in an existing Elastic Stack instance

The following instructions assume that you have an existing Elastic Stack instance into which you want to install the Kibana dashboards that are provided by this repository. For details on installing Elastic Stack, see the documentation on the Elastic website.

The following instructions are also useful for understanding the Docker image, which automates these steps.

### Import Kibana saved objects

Import the saved objects in the `kibana/export.ndjson` file into Kibana.

Either:
-   In the Kibana UI, select Management ► Stack Management ► Kibana: Saved Objects ► Import
-   Use the Kibana import saved objects API

**Tip:** Rather than importing into the default space, import into a Kibana space that you have created specifically for these dashboards.

### Create an Elasticsearch index lifecycle management (ILM) policy

Use the `elasticsearch/omegamon-ilm-policy.json` file as the body of an Elasticsearch create lifecycle policy API request.

Example API request:

````sh
curl -X PUT -H "Content-Type: application/json" -d @omegamon-ilm-policy.json "http://localhost:9200/_ilm/policy/omegamon-ilm-policy"
````

**Notes:**

-   The supplied policy definition has an active Delete phase that deletes indices after 30 days.
-   Using this policy means that the sample data will be deleted 30 days after you load it into Elasticsearch. (The age of the events in the sample data is not relevant. The lifecycle clock starts when an index is created, regardless of the event time stamps.)
-   If you *don't* configure a lifecycle policy, and you keep forwarding data to this Elasticsearch instance, then you will eventually run out of disk space.
-   For details on creating index lifecycle policies and associating them with indices, see the [Elastic Stack ILM documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html).

### Create an Elasticsearch index template

Use the `elasticsearch/omegamon-index-template.json` file as the body of an Elasticsearch create index template API request.

Example API request:

````sh
curl -X PUT -H "Content-Type: application/json" -d @omegamon-index-template.json "http://localhost:9200/_index_template/omegamon"
````

The supplied index template definition sets the number of replicas for each index to 0:

```json
"number_of_replicas": 0
```

This setting is appropriate only in the context of a single-node Elastic Stack instance, such as the stand-alone Docker container based on the supplied `Dockerfile`. You might choose to remove this setting, and also further customize the index template to meet your site-specific requirements.

Otherwise, the index template has only one purpose: to map incoming string fields to the `keyword` data type, rather than the default `text` data type.

### Customize Kibana settings

The following customizations are recommendations only, to improve your user experience of the sample dashboards.

#### Avoid incomplete lists of terms in Controls dropdowns

With default Kibana settings, depending on the number of documents you have indexed, the list of terms available in a Kibana Controls dropdown might be incomplete. In the same dashboard, you might see terms in charts *that are not available in a Controls dropdown for that field*.

There are [many topics in the Elastic Kibana discussion forum](https://discuss.elastic.co/search?q=terms%20list%20incomplete%20%23elastic-stack%3Akibana) about this issue.

The recommended "fix" (sic, deliberately in quotes): in `$KIBANA_HOME/config/kibana.yml`, set high values for the following settings. For example:

```yaml
kibana.autocompleteTimeout: 5000
kibana.autocompleteTerminateAfter: 10000000
```

**Tip:** Before editing `kibana.yml`, stop Kibana. For example, in a Linux command shell, enter `service kibana stop`. After editing, restart Kibana: enter `service kibana start`.

#### Ignore filter if field is not in index

Pinned filters in Kibana are useful to maintain consistent filtering when switching between dashboards. For example, to limit results to a particular system. However, different dashboards use different index patterns. If a visualization uses an index pattern that does not contain the field whose value is restricted by a pinned filter, then, by default, the visualization shows no results.

For example, some dashboards can be usefully filtered by the `job_name` field, so it makes sense for users to pin a filter for `job_name`. However, the data for other dashboards does not include a `job_name` field. For those dashboards, by default, a `job_name` filter causes the dashboard visualizations to display "No results found".

To ignore a filter if the field is not in the index pattern, switch on the `courier:ignoreFilterIfFieldNotInIndex` setting.

### Configure Logstash to listen for data

Copy the `logstash/pipeline/10-omegamon-tcp-to-local-elasticsearch.conf` file to the `/etc/logstash/conf.d/` directory.

Unless you have configured Logstash to automatically detect new pipeline configurations, stop and then restart Logstash.

For example, to stop the Logstash service on Linux, enter:

```sh
service logstash stop
```

Logstash can take a while to respond to that command (the signal to stop). If the response from that command ends with:

> logstash stop failed; still running.

wait for several seconds, and then enter:

```sh
service logstash status
```

You want to see:

> logstash is not running

Enter:

```sh
service logstash start
```

### Test the Logstash config with a single event

Optionally, before forwarding “real” data (your own data, or the supplied sample data) to Logstash, you might wish to test the Logstash config by forwarding a single event.

The file `data/omegamon-1-line-test.jsonl` contains a single event intended for testing the Logstash config. Use a TCP forwarder to send the file to the listening TCP port.

For example, use a tool such as `socat` (used by the Docker image):

```sh
socat -u omegamon-1-line-test.jsonl TCP4:localhost:5046
```

or `ncat`:

```sh
ncat --send-only -v localhost 5046 < omegamon-1-line-test.jsonl
```

where `localhost` is the hostname of the computer running Logstash and `5046` is the port on which Logstash is listening.

Check that the event has been indexed. For example, on the Kibana Discover tab, select the `omegamon-*` index pattern, and then set a filter for the `table_name` field value `test`.

### Forward the sample data to Logstash

Perform this step only if you want to use the provided sample data.

Use a TCP forwarder to send the sample data file, `data/omegamon-sample-data.jsonl`, to the listening TCP port.

For example:

```sh
socat -u omegamon-sample-data.jsonl TCP4:localhost:5046
```

### Browse the Kibana dashboards

Use your web browser to go to the following Kibana URL:

```
http://localhost:5601/s/omegamon/app/dashboards#/view/d24954f0-a7e6-11eb-b38d-7b8e5ab9c939?_g=(time:(from:'2021-10-13T12:00:01.999Z',to:'2021-10-13T13:59:55.999Z'))
```

-   `localhost` assumes that you are using the Elastic Stack installed on your local computer. If that is not the case, replace `localhost` with the hostname or IP address of the computer where you have installed the dashboards.

-   The `time` parameter in the URL specifies the time range of the sample data, so that you do not have to specify this range to Kibana yourself.

-   The dashboard developers recommend the Chrome web browser.

Your web browser should display a "home" dashboard that is an entry point to the other sample dashboards. Click a dashboard and begin exploring the data. For details on using Kibana, see the [Kibana User's Guide](https://www.elastic.co/guide/en/kibana/7.14/).

## Elasticsearch index names and Kibana index patterns

The supplied Logstash config uses the following `index` option to set Elasticsearch index names:

```ruby
index => "omegamon-%{table_name}-%{+YYYY.MM.dd}"
```

where `table_name` is a field in the incoming JSON data, with a value such as `"ascpuutil"`.

The sample dashboards use corresponding table-specific index patterns, such as `omegamon-ascpuutil-*`.

To help you explore and experiment with the data, the supplied saved objects include an `omegamon-*` index pattern that searches data across all tables.

## Deleting the sample data

Suppose that you have installed the sample data. Later, you decide to use the same Elastic Stack instance for your own data. You might want to delete the sample data first.

To delete all Elasticsearch indices for the sample data, send the following Elasticsearch REST API request (for example, using the Dev Tools option in Kibana):

```
DELETE /omegamon-*
```

## Forwarding your own data

If you have IBM Z OMEGAMON Data Provider, you can visualize OMEGAMON attributes from your own systems in the sample dashboards.

The sample dashboards use the following attribute groups with the specified collection intervals:

| `table_name` field value | Attribute group                       | Collection interval (minutes) |
| ------------------------ | ------------------------------------- | ----------------------------- |
| ascpuutil                | Address Space CPU Utilization         |                             1 |
| km5msucap                | KM5 License Manager MSU WLM Cap       |                             5 |
| km5wlmclpx               | WLM Class Sysplex Metrics             |                             1 |
| km5wlmclrx               | WLM Class Raw Extended Metrics        |                             1 |
| lpclust                  | LPAR Clusters                         |                             1 |
| m5stgcdth                | Common Storage Utilization History    |                             5 |
| m5stgdeth                | KM5 Storage Details History           |                             5 |
| m5stgfdth                | Real Storage Utilization History      |                             5 |
| mplxcpcsum               | KM5 CPC Summary                       |                             1 |
| mrptcls                  | Report Classes                        |                             1 |
| syscpuutil               | System CPU Utilization                |                             1 |


To visualize your own data in the sample dashboards:

1.  Create historical collections that match the attribute groups and collection intervals used by the sample dashboards (see the previous table).

2.  Configure IBM Z OMEGAMON Data Provider to forward attributes from those groups to Logstash as JSON Lines over TCP.

    The following IBM Z OMEGAMON Data Provider collection configuration parameters match the specifications in the previous table:

    ```yaml
    collections:                
      - product: km5            
        table: ascpuutil        
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: km5msucap        
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: km5wlmclpx       
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: km5wlmclrx       
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: lpclust          
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: m5stgcdth        
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: m5stgdeth        
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: m5stgfdth        
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: mplxcpcsum       
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: mrptcls          
        interval: 0             
        destination: [pds, open]
      - product: km5            
        table: syscpuutil       
        interval: 0             
        destination: [pds, open]
    ```
