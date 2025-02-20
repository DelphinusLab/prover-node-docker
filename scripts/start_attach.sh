#!/bin/bash

# Set `RUN_MONITOR` to skip if `ALERT_POST_URL` is empty. This disables monitoring if the url is not set.
if [ ! -e "scripts/.env" ]; then
    echo "scripts/.env does not exist! Required for start up."
    exit 1
fi
source scripts/.env
if [ "$ALERT_POST_URL" == "" ]; then
    export RUN_MONITOR="skip"
else
    export RUN_MONITOR=""
fi

docker compose down  # Stop any existing services

docker compose up --attach rocksdb --attach params-ftp --attach prover-dry-run-service --attach prover-node
