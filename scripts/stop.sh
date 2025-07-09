try_stop_zkwasm_mongodb() {
    # also try stop previous zkwasm-mongodb service
    docker container stop zkwasm-mongodb >/dev/null 2>&1
    docker container rm zkwasm-mongodb >/dev/null 2>&1
    docker container stop zkwasm-rocksdb-data >/dev/null 2>&1
    docker container rm zkwasm-rocksdb-data >/dev/null 2>&1
    docker container stop prover-node-docker-prover-dry-run-service-1 >/dev/null 2>&1
    docker container rm prover-node-docker-prover-dry-run-service-1 >/dev/null 2>&1
    docker container stop params-ftp >/dev/null 2>&1
    docker container rm params-ftp >/dev/null 2>&1
    docker image rm zkwasm:latest >/dev/null 2>&1
}

# Stop prover node services
docker compose down >/dev/null 2>&1

try_stop_zkwasm_mongodb
