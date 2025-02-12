docker compose down  # Stop any existing services

docker compose up --attach mongodb --attach params-ftp --attach prover-dry-run-service --attach prover-node