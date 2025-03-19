try_stop_zkwasm_mongodb() {
    # also try stop previous zkwasm-mongodb service
    docker container stop zkwasm-mongodb &> /dev/null
    docker container rm zkwasm-mongodb &> /dev/null
}

# Stop prover node services
docker compose down