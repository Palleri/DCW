#!/bin/bash

# Get the container ID as a command-line argument
CONTAINER_ID=$1

# Get the container name
CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $CONTAINER_ID | sed 's/^\///')

# Extract the container configurations to a temporary file
TMP_FILE=$(mktemp)
docker inspect $CONTAINER_ID > $TMP_FILE

# Extract the first object from the array (if applicable)
if [[ $(jq '. | type' $TMP_FILE) == "\"array\"" ]]; then
    jq '.[0]' $TMP_FILE > $TMP_FILE.tmp
    mv $TMP_FILE.tmp $TMP_FILE
fi

# Create the new container using the Docker API
curl --unix-socket /var/run/docker.sock \
     -H 'Content-Type: application/json' \
     --data-binary "@$TMP_FILE" \
     -X POST "http:/v1.24/containers/create?name=$CONTAINER_NAME-copy"

# Clean up the temporary file
rm $TMP_FILE

docker stop $1
docker rm $1
docker rename $CONTAINER_NAME-copy $1
docker start $1