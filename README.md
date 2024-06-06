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

### MongoDB Configuration

MongoDB will work "out-of-the-box", however, if you need to do something specific, please refer the following section.

#### Customising the MongoDB docker container

##### The `mongo` docker image

For our `mongo` DB docker instance we are using the official docker image provided by `mongo` on their docker hub page, [here](https://hub.docker.com/_/mongo/), `mongo:latest`. They link to the `Dockerfile` they used to build the image, at the time of writing, [this](https://github.com/docker-library/mongo/blob/ea20b1f96f8a64f988bdcc03bb7cb234377c220c/7.0/Dockerfile) was the latest. It's important to have a glance at this if you want to customise our setup. The most essential thing to note is the **volumes,** which are `/data/db` and `/data/configdb`; any files you wish to mount should be mapped into these directories. Another critical piece of info is the **exposed port**, which is `27017`; this is the default port for `mongod`, if you want to change the port you have to bind it to another port in the `docker-compose.yml` file.

##### The `mongo` daemon config file

Even though we use a pre-build `mongo` image, this doesn't limit our customisability, because we are still able to pass command line arguments into the image via the `docker-compose` file. The most flexible way of customisation is by specifying a `mongod.conf` file and passing it to `mongod` via `--config` argument, this is what we have done to set the db path. The full list of customisation options are available [here.](https://www.mongodb.com/docs/manual/reference/configuration-options/)

##### The docker compose config file

###### DB Storage

Important to note is that our db storage is mounted locally under `./mongo` directory. The path is specified in the `mongod.conf` and the mount point is specified in `docker-compose.yml`. If you want to change the where the storage is located on the host machine, you only need to change the mount bind, for example to change the storage path to `/home/user/anotherdb`.
```yaml
services:
  mongodb:
     volumes:
       - /home/user/anotherdb:/data/db
```
###### DB Port

We don't set the **PORT** in the config file, rather, **the PORT is set in `docker-compose.yml`**; simply change the bindings, so your specific port is mapped to the port used by `mongo` image, e.g. changing port to `8099` is done like so:
```yaml
services:
  mongodb:
    ports:
      - '8099:27017'
```

###### Logging and log rotation

`mongo`'s logging feature is very basic and doesn't have the ability to clean up old logs, so instead we use dockers logging feature.

Docker logs all of standard output of a container into the folder `/var/lib/docker/containers/<container-id>/`.
Log rotation is enabled for both containers. Let's walk through the specified configuration parameters:
- `driver: "json-file"`: Specifies the logging driver. The json-file driver is the default and logs container output in JSON format.
- `max-size: "10m"`: Sets the maximum size of each log file to 10 megabytes. When this is exceeded the log is rotated.
- `max-file: "3"`: Specifies the maximum number of log files to keep. When the maximum number is reached, the oldest log file is deleted.
More details can be found [here](https://docs.docker.com/config/containers/logging/configure/).

###### Network mode

Finally, we use `host` `network_mode`, this is because our server code refers to `mongo` DB via its local IP, i.e. localhost; if we want to switch to docker network mode then the code would need to be updated to use the public IP which would just be the host's public IP.

## Start

Start the docker container simply with the following command

`docker compose up`

To start multiple containers on a machine, use the following command

`docker compose -p <node> up` where `node` is the name of the container you would like to start.

Ensure the docker compose file has GPU's specified for each container.
