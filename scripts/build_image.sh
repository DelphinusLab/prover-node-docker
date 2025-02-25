# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Call check_dependencies.sh using its absolute path
sh "$SCRIPT_DIR/check_env.sh"

# If check_dependencies.sh failed, stop execution
if [ $? -ne 0 ]; then
    echo "Environment check error. Stopping execution. Please check README Environment for how to set up environment."
    exit 1
fi

DOCKER_BUILDKIT=0 docker build --rm --network=host -t zkwasm .