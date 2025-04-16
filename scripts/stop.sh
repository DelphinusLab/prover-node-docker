try_stop_zkwasm_mongodb() {
    # also try stop previous zkwasm-mongodb service
    docker container stop zkwasm-mongodb >/dev/null 2>&1
    docker container rm zkwasm-mongodb >/dev/null 2>&1
}

# Stop prover node services
docker compose down >/dev/null 2>&1

try_stop_zkwasm_mongodb
