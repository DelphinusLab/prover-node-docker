# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Clean mongodb data for legacy nodes
docker volume rm prover-node-docker_mongodb_data &> /dev/null

# Call check_dependencies.sh using its absolute path
sh "$SCRIPT_DIR/check_env.sh"

# If check_dependencies.sh failed, stop execution
if [ $? -ne 0 ]; then
    echo "Environment check error. Stopping execution. Please check README Environment for how to set up environment."
    exit 1
fi

# This script will perform some basic actions for when the prover node is upgraded.
# Manually run this script to clear the workspace and rebuild the docker image.

# This script also assumes the prover node has been started using defaults.
# If you used docker compose -p <project_name> up, then please modify the script to use the correct project name.

# Prune unused docker containers
docker container prune -f

# Prune unused docker volumes
docker volume prune -f

# Remove the workspace volume
docker volume rm prover-node-docker_workspace-volume

# Remove rocksdb data
docker volume rm prover-node-docker_rocksdb_data

# Remove the image and re-pull the latest image
docker image rm rhaoio/prover-node-dev:latest