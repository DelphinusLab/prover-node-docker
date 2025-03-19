docker compose down  # Stop any existing services

docker compose up --attach rocksdb --attach params-ftp --attach prover-dry-run-service --attach prover-node