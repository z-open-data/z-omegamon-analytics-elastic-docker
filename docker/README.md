# Docker image: Sample Elastic Kibana dashboards for IBM Z OMEGAMON Data Provider

The `z-omegamon-analytics-elastic` [Docker](https://www.docker.com/products/overview) image demonstrates visualizing OMEGAMON attributes from IBM Z OMEGAMON Data Provider in Elastic Kibana dashboards.

This image contains the Elastic Stack configured with:

- Kibana dashboards for analyzing OMEGAMON attributes
- Sample data for the dashboards

This image provides a quick way to try the dashboards in a self-contained “sandbox” environment, with sample data.

## Getting started

To start using the dashboards in a Docker container:

1.  Get a Docker host. Either:
    - [Install Docker](https://www.docker.com/get-docker) on your personal computer, or
    - Contact your organization's software support for details of an existing Docker host

    If you install Docker, follow the installation instructions on the Docker website, including the steps to verify installation. In particular, ensure that you can successfully run the Docker “hello world” example.

2.  Check that your Docker host virtual memory settings meet the [Elasticsearch requirements](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html).

3.  Build the Docker image.

    Enter the following command in the root directory of this repository (containing the `Dockerfile`):

    ````sh
    docker build -t z-omegamon-analytics-elastic .
    ````

    Note the trailing period preceded by a space.

4.  Start a container.

    For example, on your Docker host, open a command prompt and enter the following command:

    ```sh
    docker run -d -p 15601:5601 -p 19200:9200 -p 15046:5046 -v elastic-data:/var/lib/elasticsearch --name z-omegamon-analytics-elastic z-omegamon-analytics-elastic
    ```

    By default, the Docker container creates a Kibana space with the ID `omegamon`, and then imports saved objects into that space. You can set environment variables on the `docker run` command line to create a different space. For details, see “Setting environment variables to control the container startup behavior”.

    The `-p` command options map ports inside the container to the following ports on your Docker host:

    -   Logstash listens for incoming JSON Lines data on TCP port 15046. To add your own data to the container, forward JSON Lines to this port.
    -   Kibana is on HTTP port 15601.
    -   The Elasticsearch API is on HTTP port 19200.

    If these port numbers clash with existing port assignments on your Docker host, feel free to use different port numbers. For details, see the [Docker command reference documentation](https://docs.docker.com/engine/reference/commandline/run/#publish-or-expose-port--p-expose).

    The `--name` option specifies the name of the new Docker container. In this example `docker run` command, the container has the same name as the image. (The image name is the last argument on the command line.) You can choose to specify a different container name.

    The `-v` option creates a named volume for the container directory that stores Elasticsearch indices, rather than creating a volume with a non-semantic generated ID. Semantic names can make volumes easier to manage. For example, to remove this volume later, rather than having to identify and refer to the corresponding volume ID, you can refer to it by name: `docker volume rm elastic-data`.

    **Recommendations:**

    -   Do not share a volume between containers that are based on this image.

        If you start more than one container based on this image on the same Docker host, then use a different volume for each container. You might choose to use a volume naming convention that corresponds to container names.

    -  When you remove a container that is based on this image, also remove its volume.

       Unless you purposefully, deliberately want to do so (for example, you want to keep your own data that you have forwarded from your own systems), and you understand the related issues, such as the compatibility of Elasticsearch index data formats between versions, do not reuse an existing volume for a new container.

5.  Wait: for the Docker image to download, for the container to start, and then for the container to initialize Elastic with the supplied dashboards and data. Depending on your connection the web, the Docker image might take several minutes to download. After that, the container might take another minute to initialize, depending on your Docker host.

6.  Browse to the following Kibana URL:
    ```
    http://localhost:15601/s/omegamon/app/dashboards#/view/d24954f0-a7e6-11eb-b38d-7b8e5ab9c939?_g=(time:(from:'2021-10-13T12:00:01.999Z',to:'2021-10-13T13:59:55.999Z'))
    ```

    -   Replace `localhost` in the URL with the name of your Docker host.
    -   The `time` parameter in the URL specifies the time range of the sample data, so that you do not have to specify this range to Kibana yourself.
    -   We recommend the Chrome web browser.

Your web browser should display a "home" dashboard that is an entry point to the other sample dashboards. Click a dashboard and begin exploring the data. For details on using Kibana, see the [Kibana User's Guide](https://www.elastic.co/guide/en/kibana/7.14/).

When the container starts, it loads data into Elastic. Kibana allows you to view dashboards while the data is still loading, so you might see partially filled charts, such as vertical time-based bar charts with little or no data showing on the right-hand side. If this happens, wait a little longer, and then refresh the page in your browser (for example, press F5).

If your web browser does not display a list of Kibana dashboards, or you click a dashboard and the dashboard contains no data, or you experience some other problem, see “Troubleshooting”.

## Upgrading from an earlier version of this repository

If you have an old Docker container based on an earlier version of this repository, and you want to upgrade to a new container, consider using the following steps (these are recommendations only; vary them depending on your needs):

1.  Stop and remove the old container. Example:

    ````
    docker rm -f z-omegamon-analytics-elastic
    ````
2.  Remove the volume used by the old container. Example (depending on the volume name you used for the old container):

    ````
    docker volume rm elastic-data
    ````

    **Tip:** To remove unused volumes without referring to specific volume names, use `docker volume prune`.

    If you do not remove the volume, and you specify the same volume name when starting a new container, then the new container will use the same volume, with data from the old container. Reusing that volume might cause issues with the new container, for a variety of reasons, such as differences in the Elasticsearch index data format between versions.

3.  Rebuild the Docker image from the updated repository, and then start a new container. For details, see "Getting started".

## Troubleshooting and support

Before seeking support for this image, please ensure that you can successfully run the Docker “hello world” example described in the Docker documentation. Please do not use the support contact details provided here for general Docker issues.

If you experience a problem using these dashboards, enter the following command on your Docker host, and save the command output:

```sh
docker logs z-omegamon-analytics-elastic
```

then contact your local Docker expert or IBM Software Support.

### Common issues

#### Elasticsearch error: IndexFormatTooNewException (Format version is not supported)

**Explanation:** Elasticsearch has encountered indices in a format version that is not supported by this version of Elasticsearch.

**Probable cause:** A new Docker container has been started. The new container uses the same volume as this container (the container in which this error occurred). The new container uses a more recent version of Elasticsearch. Elasticsearch in the new container has loaded data into the same volume (the same directory, the same indices) used by this container. Elasticsearch in this container does not support the index format used by the newer version.

**Recommended action:** Do not share volumes between containers. Stop and remove both containers. Remove the volume that has been "polluted" by the new data. Start new containers using a separate volume for each container.

## Tips for new Docker users

### Stopping the container

The `docker run` command in the “Getting started” procedure specifies a `-d` option that starts a container in “detached” mode rather than the default foreground mode.

In detached mode, the container continues running after you close the command shell that you used to start it, so you don't need to keep that command shell open.

To stop the container, enter the following command:

```sh
docker stop z-omegamon-analytics-elastic
```

Shutting down your computer stops Docker and the container. When you reboot your computer and Docker restarts, the container will _not_ restart automatically: you need to restart it. To change this behavior, see the Docker documentation on restart policies.

### Restarting the container

To restart the container after stopping it or after rebooting your computer, enter the following command:

```sh
docker restart z-omegamon-analytics-elastic
```

### Other Docker commands

To list containers, both running and stopped, use the `docker ps -a` command.

To remove a container, use the `docker rm` command.

For more information about Docker commands, see the [Docker documentation](https://docs.docker.com/engine/reference/commandline/cli/).

## Loading data into the container

In the container, Logstash is configured to listen for JSON Lines on TCP port 5046.

## Create an Elasticsearch index lifecycle management (ILM) policy

The Docker image does not configure index lifecycle policy. If you plan to forward your own data to this Elastic Stack instance, then consider creating an index lifecycle policy now to avoid running into disk capacity issues later.

As a starting point, consider creating a policy with an active Delete phase that deletes data after 30 days. Use the `elasticsearch/omegamon-ilm-policy.json` file as the body of an Elasticsearch create lifecycle policy API request (`PUT _ilm/policy/omegamon-ilm-policy`). Then add that policy name to the `omegamon` index template settings:

```json
"index.lifecycle.name": "omegamon-ilm-policy"
```

For details on creating index lifecycle policies and associating them with indices, see the [Elastic Stack ILM documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html).

## Setting environment variables to control the container startup behavior

When you start a container for the first time, you can set environment variables to control the container startup behavior.

These variables are in addition to the environment variables provided by the base `sebp/elk` image.

### Controlling the loading of sample data and Kibana saved objects

To control loading of sample data and Kibana saved objects into the container, set the following environment variables. (The saved objects define the sample dashboards.)

-   `INSTALL_SAMPLES`\
    Default value: `1`, which loads the sample data and Kibana saved objects (dashboards, visualizations, saved searches, and index patterns).

    To disable all loading, set to `0` and omit all other variables.

-   `INSTALL_SAMPLE_DATA`\
    Defaults to the value of `INSTALL_SAMPLES`.

    To skip loading the sample data, set to `0`.

    To load the sample data, set to `1`.

-   `INSTALL_SAMPLE_OBJECTS`\
    Defaults to the value of `INSTALL_SAMPLES`.

    To skip loading Kibana objects, set to `0`.

    To load Kibana objects, set to `1`.

If you load Kibana saved objects but not the sample data, then you will need to load your own data.

You can set these environment variables using the `-e` option of the `docker run` command.

For example, if you want to use the sample dashboards, but you want to omit the sample data because you plan to forward your own logs to the container, set `INSTALL_SAMPLE_OBJECTS=1` and `INSTALL_SAMPLE_DATA=0`:

```sh
docker run -d -p 15601:5601 -p 19200:9200 -p 15046:5046 -v elastic-data:/var/lib/elasticsearch -e INSTALL_SAMPLE_DATA=0 -e INSTALL_SAMPLE_OBJECTS=1 --name z-omegamon-analytics-elastic z-omegamon-analytics-elastic
```

### Controlling the Kibana space into which the saved objects are imported

To control which Kibana space the saved objects are imported into, set the following environment variables.

The Docker image creates a Kibana space, and then imports saved objects into that space. You can override the default space ID, description, and initials.

-   `KIBANA_SPACE_ID`\
    Default value: `omegamon`

-   `KIBANA_SPACE_NAME`\
    Default value: `OMEGAMON analytics`

-   `KIBANA_SPACE_INITIALS`\
    Default value: `OM`

## Extending the Docker image

The Docker image defined in this repository is based on the `sebp/elk` image from Docker Hub.

This repository includes a shell script, `docker/elk-post-hooks.sh`, that is run by the "post-hooks" feature of the base image.

The `sebp/elk` base image provides numerous configuration features. Before extending the Docker image defined in this repository, read the [`sebp/elk` documentation](https://elk-docker.readthedocs.io/).
