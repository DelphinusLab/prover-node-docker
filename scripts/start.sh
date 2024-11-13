# Start FTP server containing param files first
# This can remain running between prover node upgrades
docker compose -f ftp-docker-compose.yml up -d

# Start prover node services
docker compose up