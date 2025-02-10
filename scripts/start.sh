#!/bin/bash

# Start all services in detached mode
docker-compose up -d

# Function to wait for a service to be healthy (modify as needed)
wait_for_service() {
    service_name=$1
    echo "Waiting for $service_name to be healthy..."
    while [ "$(docker inspect --format='{{.State.Health.Status}}' ${service_name})" != "healthy" ]; do
        sleep 1
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

# Start services in order
show_logs_temporarily mongodb

# Finally, attach to other services
echo "Now attaching logs for prover dry-run service..."
docker-compose logs -f prover-dry-run-service

echo "Now attaching logs for prover node service..."
docker-compose logs -f prover-node