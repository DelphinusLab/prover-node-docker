#!/bin/bash

# Set `RUN_MONITOR` to skip if `ALERT_POST_URL` is empty. This disables monitoring if the url is not set.
if [ ! -e "scripts/.env" ]; then
    echo "scripts/.env does not exist! Required for start up."
    exit 1
fi
. scripts/.env
if [ "$ALERT_POST_URL" = "" ]; then
    export RUN_MONITOR="skip"
else
    export RUN_MONITOR=""
fi

docker compose down  # Stop any existing services

# Check zkwasm (prover node) image exists, if not ask the user to build it.
if docker images | grep "^zkwasm[[:space:]]" &> /dev/null; then
    echo "OK: Prover node image found"
else
    echo "ERR: prover node image not found. please build it using 'bash scripts/build_image.sh'"
    exit 1
fi

# Function to wait for a service to be healthy (modify as needed)
wait_for_service() {
    service_name=$1
    echo "Waiting for $service_name to be healthy..."
    while [ "$(docker inspect --format='{{.State.Health.Status}}' ${service_name})" != "healthy" ]; do
        echo "Waiting for $service_name to be healthy..."
        sleep 5
    done
}

# Function to show logs of a service temporarily
show_logs_temporarily() {
    service_name=$1
    echo "Showing logs for $service_name..."
    docker logs -f $service_name &
    log_pid=$!
    
    wait_for_service $service_name  # Wait for the service to be ready

    # Once the service is ready, stop displaying logs
    kill $log_pid
}
docker compose up -d params-ftp

show_logs_temporarily prover-node-docker-params-ftp-1

# Finally, attach to other services
docker compose up
