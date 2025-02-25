#!/bin/sh

# Function to check if a command exists
check_command() {
    which "$1" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: $1 is not installed."
        return 1
    fi
}

# Check for nvidia-smi
check_command "nvidia-smi" || exit 1

# Check if nvidia-smi runs successfully
nvidia-smi > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: nvidia-smi is installed but failed to run. Check your NVIDIA drivers."
    exit 1
fi
echo "Success: nvidia-smi is installed and running properly."

# Check for Docker
check_command "docker" || exit 1

# Check if Docker is running
systemctl is-active --quiet docker
if [ $? -ne 0 ]; then
    echo "Error: Docker is installed but not running. Start it using: sudo systemctl start docker"
    exit 1
fi
echo "Success: Docker is installed and running."

# Check if Docker supports `docker compose`
docker compose version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Docker Compose plugin is not installed. Install it with: sudo apt install docker-compose-plugin"
    exit 1
fi
echo "Success: Docker Compose plugin is installed."

# Check for NVIDIA Container Toolkit
dpkg -l | grep -q "nvidia-container-toolkit"
if [ $? -ne 0 ]; then
    echo "Error: NVIDIA Container Toolkit is not installed."
    exit 1
fi
echo "Success: NVIDIA Container Toolkit is installed."

# If all checks pass
echo "All dependencies are installed and working correctly."
exit 0
