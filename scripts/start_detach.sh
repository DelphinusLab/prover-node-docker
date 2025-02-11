docker compose down  # Stop any existing services

echo "Starting services in detached mode..."
echo "If you want to attach to the logs, run 'docker compose logs -f --tail 100'"
echo "Alternatively for each service, run 'docker compose logs -f <service_name> --tail 100'"

docker compose up -d