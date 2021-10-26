#!/bin/bash

# Post-hooks shell script for the sebp/elk Docker image

# When the container starts, if requested, load sample data into Elasticsearch and saved objects into Kibana

# Thanks to processing by the sebp/elk start.sh that calls this script, we can assume that Kibana and Elasticsearch are up

# Environment variables
LOGSTASH_HTTP_URL="http://localhost:9600"
LOGSTASH_TCP_URI="localhost:5046"
INDEX_TEMPLATE_NAME="omegamon"
ILM_POLICY_NAME="omegamon-ilm-policy"

# Default to installing sample data and saved objects
INSTALL_SAMPLES="${INSTALL_SAMPLES:=1}"
INSTALL_SAMPLE_DATA="${INSTALL_SAMPLE_DATA:=$INSTALL_SAMPLES}"
INSTALL_SAMPLE_OBJECTS="${INSTALL_SAMPLE_OBJECTS:=$INSTALL_SAMPLES}"

# The following files have been copied into the container by the Dockerfile
SAMPLE_OBJECTS_PATH="/opt/container/kibana/export.ndjson"
KIBANA_SPACE_PATH="/opt/container/kibana/omegamon-space.json"
INDEX_TEMPLATE_PATH="/etc/logstash/conf.d/omegamon-index-template.json"
ILM_POLICY_PATH="/etc/logstash/conf.d/omegamon-ilm-policy.json"
SAMPLE_DATA_PATH="/opt/container/data/omegamon-sample-data.jsonl"

# Kibana space properties
KIBANA_SPACE_ID="${KIBANA_SPACE_ID:="omegamon"}"
KIBANA_SPACE_NAME="${KIBANA_SPACE_NAME:="OMEGAMON Data Provider"}"
KIBANA_SPACE_INITIALS="${KIBANA_SPACE_INITIALS:="OM"}"

# Tools
# Run curl in silent (-s) mode, but show errors (-S)
CURL="curl -sS"
SOCAT="socat"

# Function definitions

# Check if a server is ready by waiting for a successful response
function is_ready() {
  local url=$1
  local name=$2
  local limit=${3:-30}
  local counter=0
  # Wait for a successful (non-empty) response
  echo "Checking if $name is up..."
  while [ ! "$($CURL $url 2> /dev/null)" -a $counter -lt $limit ]; do
    sleep 1
    counter=$((counter+1))
    echo "Waiting for $name to be up ($counter/$limit)"
  done
  if [ ! "$($CURL $url 2> /dev/null)" ]; then return 1; fi
  echo "$name is up."
  return 0
}

# Wait for Logstash pipeline to starting listening on TCP port
function is_logstash_pipeline_listening() {
  local cmd="$SOCAT /dev/null TCP4:$LOGSTASH_TCP_URI"
  local limit=${3:-30}
  local counter=0
  # Wait for a successful (empty) response
  echo "Checking if Logstash pipeline is listening on $LOGSTASH_TCP_URI..."
  while [ "$($cmd 2>&1)" -a $counter -lt $limit ]; do
    sleep 1
    counter=$((counter+1))
    echo "Waiting for Logstash pipeline to start listening ($counter/$limit)"
  done
  if [ "$($cmd 2>&1)" ]; then return 1; fi
  echo "Logstash pipeline is listening."
  return 0
}

# Use the Kibana import objects API to import save objects that have been exported to a .ndjson file
function import_objects() {
  local file=$1
  $CURL -X POST -H "kbn-xsrf: true" --form file=@$file "${KIBANA_URL}/s/${KIBANA_SPACE_ID}/api/saved_objects/_import?overwrite=true" > /dev/null || return 1
  return 0
}

# Use the Kibana create space API to create a space
function create_space() {
  local file=$1
  # Customize space properties in JSON file
  sed -i -r -e 's|(\"id\"\s*:\s*\")[^\"]*|\1'"${KIBANA_SPACE_ID}"'|g' \
         -e 's|(\"name\"\s*:\s*\")[^\"]*|\1'"${KIBANA_SPACE_NAME}"'|g' \
         -e 's|(\"initials\"\s*:\s*\")[^\"]*|\1'"${KIBANA_SPACE_INITIALS}"'|g' \
         $file
  $CURL -X POST -H "Content-Type: application/json" -H "kbn-xsrf: true" -d @$file "${KIBANA_URL}/api/spaces/space" > /dev/null || return 1
  return 0
}

# Use the Elasticsearch create or update index template API to create an index template
function create_index_template() {
  local file=$1
  $CURL -X PUT -H "Content-Type: application/json" -d @$file "${ELASTICSEARCH_URL}/_index_template/${INDEX_TEMPLATE_NAME}" > /dev/null || return 1
  return 0
}

# Use the Elasticsearch create or update lifecycle policy API to create a lifecycle policy
function create_ilm_policy() {
  local file=$1
  $CURL -X PUT -H "Content-Type: application/json" -d @$file "${ELASTICSEARCH_URL}/_ilm/policy/${ILM_POLICY_NAME}" > /dev/null || return 1
  return 0
}

# Send data to Logstash for forwarding to Elasticsearch
function load_data() {
  local logstash_host=$1
  local file=$2
  [ -e "$file" ] || return 0
  # Send to Logstash
  echo "Loading data from '$file'."
  $SOCAT -u $file TCP4:$logstash_host || return 1
}

# Main procedure

# Load saved objects, including dashboards
if [ "$INSTALL_SAMPLE_OBJECTS" -eq "1" ]; then
  echo "Creating Kibana space: ID '$KIBANA_SPACE_ID', name '$KIBANA_SPACE_NAME'."
  create_space $KIBANA_SPACE_PATH || exit 1
  echo "Importing Kibana objects."
  import_objects $SAMPLE_OBJECTS_PATH || exit 1
fi

# If requested, load the data
if [ "$INSTALL_SAMPLE_DATA" -eq "1" ]; then
  # Create lifecycle policy
  echo "Creating lifecycle policy '$ILM_POLICY_NAME'."
  create_ilm_policy $ILM_POLICY_PATH || exit 1
  # Create index template
  echo "Creating index template '$INDEX_TEMPLATE_NAME'."
  create_index_template $INDEX_TEMPLATE_PATH || exit 1
  # Wait for Logstash to start
  # set number of retries (default: 60, override using LS_CONNECT_RETRY env var)
  if ! [[ $LOGSTASH_CONNECT_RETRY =~ $re_is_numeric ]]; then LOGSTASH_CONNECT_RETRY=60; fi
  if ! is_ready $LOGSTASH_HTTP_URL "Logstash" $LOGSTASH_CONNECT_RETRY || ! is_logstash_pipeline_listening; then
    echo "Logstash took too long to start. Displaying Logstash log:"
    cat /var/log/logstash/logstash-plain.log
    exit 1
  fi
  # Load the data
  echo "Sending sample data to Logstash."
  load_data $LOGSTASH_TCP_URI $SAMPLE_DATA_PATH || exit 1
  echo "Sample data sent."
fi