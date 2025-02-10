#!/bin/bash

# Start mongodb first, and attach to its logs
docker compose up -d mongodb

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

# Start services in order (#container name)
show_logs_temporarily zkwasm-mongodb

# Finally, attach to other services
docker compose up