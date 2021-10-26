FROM sebp/elk:7.14.0

LABEL org.opencontainers.image.authors="Graham Hannington <graham.hannington@rocketsoftware.com>. Based on work by Liam Walmsley-Eyre in 2017."
LABEL org.opencontainers.image.vendor="IBM"
LABEL org.opencontainers.image.version="1.1.0"
LABEL org.opencontainers.image.description="Analyze IBM Z OMEGAMON attributes in the Elastic Stack."

# Components to start
ENV LOGSTASH_START=1 \
    ELASTICSEARCH_START=1 \
    KIBANA_START=1

# Set the working directory
WORKDIR /root/

# Update package index, and then install netcat (socat)
RUN apt-get update && \
    apt-get -y install socat \
    && rm -rf /var/lib/apt/lists/*

# Remove the existing Logstash pipeline configurations
RUN rm -rf /etc/logstash/conf.d/*.conf
# Copy our own Logstash config, corresponding Elasticsearch index template and lifecycle policy
COPY /logstash/pipeline/*.conf /elasticsearch/*-template.json /elasticsearch/*-ilm-policy.json /etc/logstash/conf.d/

# Append to Elasticsearch settings file: enable CORS
RUN echo '\nhttp.cors.enabled: true\nhttp.cors.allow-origin: "*"\n' >> /etc/elasticsearch/elasticsearch.yml

# Append to Kibana settings file
RUN echo '\nkibana.autocompleteTimeout: 5000\nkibana.autocompleteTerminateAfter: 10000000\n' >> /opt/kibana/config/kibana.yml

# Copy sample JSON Lines data and Kibana saved objects (dashboards)
COPY /data /opt/container/data
COPY /kibana /opt/container/kibana

# Copy post-hooks shell script and make it executable
COPY /docker/elk-post-hooks.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/elk-post-hooks.sh