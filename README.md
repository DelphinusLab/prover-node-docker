# Prover Node Docker

This is the docker container for the prover node. This container is responsible for running the prover node and handling tasks from the server.

## Table of Contents

- [Environment Setup](#environment)
  - [Setting up the Host Machine](#setting-up-the-host-machine)
- [Building](#building)
  - [Important](#important)
  - [Build the Docker Image](#build-the-docker-image)
- [Running](#running)
  - [Prover Node Configuration](#prover-node-configuration)

## Environment

The prover node requires a CUDA capable GPU, currently at minimum an RTX 4090.

The docker container is built on top of Nvidia's docker runtime and requires the Nvidia docker runtime to be installed on the host machine.

### Setting up the Host Machine

- Install NVIDIA Drivers for Ubuntu

  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#prerequisites

  https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html

  You can check if you have drivers installed with `nvidia-smi`

- Install Docker (From Nvidia, but feel free to install yourself!) https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#setting-up-docker

- Install Docker Compose
  https://docs.docker.com/compose/install/linux/#install-the-plugin-manually

- Install the Nvidia CUDA Toolkit + Nvidia docker runtime

We need to install the nvidia-container-toolkit on the host machine. This is a requirement for the docker container to be able to access the GPU.

https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#setting-up-nvidia-container-toolkit

Since the docs aren't the clearest, these are the commands to copy paste!

```
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

and then

`sudo apt-get update`

and then

`sudo apt-get install -y nvidia-container-toolkit`

Configure Docker daemon to use the `nvidia` runtime as the default runtime.

`sudo nvidia-ctk runtime configure --runtime=docker --set-as-default`

Restart the docker daemon

`sudo systemctl restart docker` (Ubuntu)

`sudo service docker restart` (WSL Ubuntu)

Another method to set the runtime is to run this script after the cuda toolkit is installed.
https://github.com/NVIDIA/nvidia-docker

`sudo nvidia-ctk runtime configure`

## Building

The image is currently built with

- Ubuntu 22.04
- CUDA 12.2
- prover-node-release #f2d2ffc6154dff58343bef325f1be8e1d234a4cf

**Important!**
The versions should not be changed unless the prover node is updated. The compiled prover node binary is sensitive to the CUDA version and the Ubuntu version.

### Build the Docker Image

Better clean the old docker image/volumes if you want.

To Build the docker image, run the following command in the root directory of the repository.

`bash build_image.sh`

We do not use BuildKit as there are issues with the CUDA runtime and BuildKit.

## Running

### Prover Node Configuration

**Important!**

This configuration file may change in the future. The prover node is currently in development and is subject to change. Ensure it is up to date with the latest version of the node.

The prover node requires a configuration file to be passed in at runtime.

- `server_url` - The URL of the server to connect to for tasks. The provided URL is the dockers reference to the host machines 'localhost'
- `priv_key` - The private key of the prover node. This is used to sign the tasks and prove the work was done by the prover node.

### HugePages Configuration

It is important to set the hugepages on the host machine to the correct value. This is done by setting the `vm.nr_hugepages` kernel parameter.

For a machine running a single prover node, the value should be set to ~15000. This is done with the following command.

`sysctl -w vm.nr_hugepages=15000`

### GPU Configuration

If you need to specify GPUs, you can do so in the `docker-compose.yml` file. The `device_ids` field is where you can specify the GPU's to use.

The starting command for the container will use `CUDA_VISIBLE_DEVICES=0` to specify the GPU to use.

You may also change the `device_ids` field in the `docker-compose.yml` file to specify the GPU's to use. Note that in the container the GPU indexing starts at 0.

Also ensure the `command` field in `docker-compose.yml` is modified for `CUDA_VISIBLE_DEVICES` to match the GPU you would like to use.

## Start

Start the docker container simply with the following command

`docker compose up`

To start multiple containers on a machine, use the following command

`docker compose -p <node> up` where `node` is the name of the container you would like to start.

Ensure the docker compose file has GPU's specified for each container.
