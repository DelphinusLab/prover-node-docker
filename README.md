# Prover Node Docker

This is the docker container for the prover node. This container is responsible for running the prover node and handling tasks from the server.

## Table of Contents

- [Environment Setup](#environment)
  - [Setting up the Host Machine](#setting-up-the-host-machine)
- [Building](#building)
  - [Build the Docker Image](#build-the-docker-image)
- [Running](#running)
  - [Prover Node Configuration](#prover-node-configuration)
  - [Dry Run Service Configuration](#dry-run-service-configuration)
  - [HugePages Configuration](#hugepages-configuration)
  - [GPU Configuration](#gpu-configuration)
  - [MongoDB](#mongodb-configuration)
  - [Multiple Nodes on the same machine](#multiple-nodes-on-the-same-machine)
- [Quick Start](#quick-start)
- [Logs](#logs)
- [Upgrading Prover Node](#upgrading-prover-node)

**_If you had installed the prover docker before, please go to the [Upgrading Prover Node](#upgrading-prover-node) section directly for upgrading._**

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
- prover-node-release #365abc4ac1b7c2859f4de8ca272834e9a1e71299

The versions should not be changed unless the prover node is updated. The compiled prover node binary is sensitive to the CUDA version and the Ubuntu version.

### Build the Docker Image

Better clean the old docker image/volumes if you want.

To Build the docker image, run the following command in the root directory of the repository.

`bash build_image.sh`

We do not use BuildKit as there are issues with the CUDA runtime and BuildKit.

## Running

### Prover Node Configuration

`prover_config.json` file is the config file for prover node service.

- `server_url` - The URL of the server to connect to for tasks. Currently the public test server's rpc is "https://rpc.zkwasmhub.com:8090".
- `priv_key` - The private key of the prover node. This is used to sign the tasks which were done by the prover node. If you want to start multiple prover nodes, please use different priv key for each node as it will represent your node. <mark>**Please note do not add "0x" at the begining of priv.**</mark>

### Dry Run Service Configuration

The Dry Run service will be required to run parallel to the prover node. The Dry Run service is responsible for synchronising tasks with the server and ensuring the prover node is working correctly.
This service must be run in parallel to the prover node, so running the service through docker compose is recommended.

`dry_run_config.json` file is the config file for prover dry run service, modify the connection strings to the server and the MongoDB instance.

- `server_url` - The URL of the server to connect to for tasks. Ensure this is the same as the prover node. Currently the public test server's rpc is "https://rpc.zkwasmhub.com:8090".
- `mongodb_uri` - The URI of the MongoDB instance to connect to. By default it is "mongodb://localhost:27017". You do not need change it if you start the prover node with `docker compose up` and use default `docker-compose.yml`.
- `private_key` - Please fill the same priv_key as the prover config. <mark>**Please note do not add "0x" at the begining of priv.**</mark>

### HugePages Configuration

It is required to set the hugepages on the host machine to the correct value. This is done by setting the `vm.nr_hugepages` kernel parameter.

Use `grep Huge /proc/meminfo` to check currently huge page settings. HugePages_Total must be more than 15000 to support one prover node.

For a machine running a single prover node, the value should be set to 15000. This is done with the following command.

`sysctl -w vm.nr_hugepages=15000`

Make sure you use `grep Huge /proc/meminfo` to check it is changed and then start docker containers.

Please note the above will only set the current running system huge pages. It will be reset after the machine restarted. If you want to keep it after restarting, add the following entry to the `/etc/sysctl.conf` file:

`vm.nr_hugepages=15000`

### Memory Requirements

We support new continuation feature from this version.
The minimum requirement of the available to run prover is **58 GB** after with HugePages_Total 15000, which is about 88 GB.

### GPU Configuration

If you need to specify GPUs, you can do so in the `docker-compose.yml` file. The `device_ids` field is where you can specify the GPU's to use.

The starting command for the container will use `CUDA_VISIBLE_DEVICES=0` to specify the GPU to use.

You may also change the `device_ids` field in the `docker-compose.yml` file to specify the GPU's to use. Note that in the container the GPU indexing starts at 0.

Also ensure the `command` field in `docker-compose.yml` is modified for `CUDA_VISIBLE_DEVICES` to match the GPU you would like to use.

## MongoDB Configuration

MongoDB will work "out-of-the-box", however, if you need to do something specific, please refer the following section.

Note: If initializing from a checkpoint, it may take time to perform the initial restore.

### Default Settings/Config

For most use cases, the default options should be sufficient.

The mongodb instance will run on port `27017` and the data will be stored in the `./mongo` directory.

Network mode is set to `host` to allow the prover node to connect to the mongodb instance via localhost, however if you prefer the port mapping method, you can change the port in the `docker-compose.yml` file.

If you are unsure about modifying or customizing changes, refer to the section below.

### Initializing a new MongoDB instance

Using our custom `mongo` image, we need to initialize the database and restore from a checkpoint.

If you run the mongodb service with default options, there is no need to configure anything as the checkpointed database will be initialized and restored automatically.

#### Using Custom MongoDB Port

If you are using a custom port (non 27017), some consideration should be made for the initialization process.

Mongodb initializes the database by spawning a temporary mongodb process which will require binding to a port.

Ensure the port is not in use by another process, otherwise the initialization will fail.

We have a custom ENV variable `MONGO_INITDB_PORT` which you can set in the `docker-compose.yml` file to specify the port for the initialization process.

This does not affect the port the mongodb instance will run on, only the port used for initialization.

```yaml
services:
  mongodb:
    network_mode: "host"
    environment:
      # Set this port if 27017 is already used by another service/mongodb instance
      # Mostly useful if using network_mode: "host", as the port will be shared.
      - MONGO_INITDB_PORT=27017
```

### Customising the MongoDB docker container

<details>
  <summary>View customization details</summary>

#### The `mongo` docker image

For our `mongo` DB docker instance we are using a wrapped `mongo` image with some extra data and initialization scripts.
It is based off `mongo:7.0`, [github link](https://github.com/docker-library/mongo/blob/ea20b1f96f8a64f988bdcc03bb7cb234377c220c/7.0/Dockerfile). The most essential thing to note is the **volumes,** which are `/data/db` and `/data/configdb`; any files you wish to mount should be mapped into these directories. Another critical piece of info is the **exposed port**, which is `27017`; this is the default port for `mongod`, if you want to change the port you have to bind it to another port in the `docker-compose.yml` file.

#### The `mongo` daemon config file

Even though we use a pre-build `mongo` image, this doesn't limit our customisability, because we are still able to pass command line arguments into the image via the `docker-compose` file. The most flexible way of customisation is by specifying a `mongod.conf` file and passing it to `mongod` via `--config` argument, this is what we have done to set the db path. The full list of customisation options are available [here.](https://www.mongodb.com/docs/manual/reference/configuration-options/)

#### The docker compose config file

##### DB Storage

Our db storage is mounted using the `mongodb_data` volume.
If you want to change the where the storage is located on the host machine, you only need to change the mount bind, for example to change the storage path to `/home/user/anotherdb`.

```yaml
services:
  mongodb:
    volumes:
      - /home/user/anotherdb:/data/db
```

##### DB Port

We don't set the **PORT** in the config file, rather, **the PORT is set in `docker-compose.yml`**; simply change the bindings, so your specific port is mapped to the port used by `mongo` image, e.g. changing port to `8099` is done like so:

```yaml
services:
  mongodb:
    ports:
      - "8099:27017"
```

If using host network mode, the port mapping will be ignored, and the port will be the default `27017`.
Specify the port by adding `--port <PORT>` to the `command` field in the `docker-compose.yml` file for the mongodb service.

**Important** If you change the DB Port under network_mode: host, you must also update the healthcheck to use the correct port.

```yaml
services:
  mongodb:
    command: --port 8099
    healthcheck:
      test: |
        mongosh --port 8099 --quiet --eval '
          const ping = db.adminCommand({ ping: 1 }).ok;
          const init = db.init_status.findOne({ "_id": "init" }) != null;
          if (ping && init) { quit(0) } else { quit(1) }
        '
```

##### Logging and log rotation

`mongo`'s logging feature is very basic and doesn't have the ability to clean up old logs, so instead we use dockers logging feature.

Docker logs all of standard output of a container into the folder `/var/lib/docker/containers/<container-id>/`.
Log rotation is enabled for both containers. Let's walk through the specified configuration parameters:

- `driver: "json-file"`: Specifies the logging driver. The json-file driver is the default and logs container output in JSON format.
- `max-size: "10m"`: Sets the maximum size of each log file to 10 megabytes. When this is exceeded the log is rotated.
- `max-file: "5"`: Specifies the maximum number of log files to keep. When the maximum number is reached, the oldest log file is deleted.
  More details can be found [here](https://docs.docker.com/config/containers/logging/configure/).

##### Network mode

Finally, we use `host` `network_mode`, this is because our server code refers to `mongo` DB via its local IP, i.e. localhost; if we want to switch to docker network mode then the code would need to be updated to use the public IP which would just be the host's public IP.

</details>

## Quick Start

We require our Params FTP Server to be running before starting the prover node. The prover node must copy the parameters from the FTP server to it's own volume to operate correctly.

`bash scripts/upgrade.sh` is required to run the first time you pull the repository or update the prover node.

To start the prover node, run:

`bash scripts/start.sh`

<details>
  <summary>Quick Start Details</summary>

### Params FTP Server

Start the FTP server with `docker compose -f ftp-docker-compose.yml up`.

The default port is `21` and the default user is `ftpuser` with password `ftppassword`. The ports used for file transfer are `30000-30009`.

### Prover Node

The docker image is built locally, and requires building with:

`DOCKER_BUILDKIT=0 docker build --rm --network=host -t zkwasm .`

Make sure you had reviewed the [Prover Node Configuration](#prover-node-configuration) part and changed the config files.

Once the Params FTP server is running, you can start the prover node.

Start all services at once with the command `docker compose up`. However it may clog up the terminal window as they all run in the same terminal so you may run some services in detached mode. For example, use `tmux` to run it.

`docker compose up` will run the base services in order of mongodb, dry-run-service, prover-node service.

</details>

## Multiple Prover Nodes

### Multiple Nodes on the same machine

<details>
  <summary>Details</summary>

To run multiple prover nodes on the same machine, it is recommended to clone the repository and modify the required files.

- `docker-compose.yml`
- `prover-node-config.json`
- `dry_run_config.json`

There are a few things to consider when running multiple nodes on the same machine.

- GPU
- MongoDB instance
- Config file information
- Docker volume and container names

#### GPU

Ensure the GPU's are specified in the `docker-compose.yml` file for each node.
It is crucial that each GPU is only used ONCE otherwise you may encounter out of memory errors.
We recommend to set the `device_ids` field where you can specify the GPU to use in each `docker-compose.yml` file.

As mentioned, use `nvidia-smi` to check the GPU index and ensure the `device_ids` field is set correctly and uniquely.

#### MongoDB instance

Ensure the MongoDB instance is unique for each node. This is done by modifying the `docker-compose.yml` file for each node.

- Modify the `mongodb`services - `container_name` field to a unique value such as `zkwasm-mongodb-2` etc.
- Set the correct port to bind to the host machine. Please refer to the MongoDB configuration section for more information.
  - If using host network mode, the port is not required to be specified under services, but may be specified as part of the command field e.g `--port 8099`.
  - If supplying a custom port with `network_mode: host`, ensure the port is unique for each node. Ensure the healthcheck is updated to use the correct port.
    ```yaml
    command: --config /data/configdb/mongod.conf --port XXXX
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:XXXX/test --quiet
    ```

Ensure the `dry_run_config.json` file is updated with the correct MongoDB URI for each node.

#### Config file information

Ensure the `prover-config.json` file is updated with the correct server URL and private key for each node.

Private key should be UNIQUE for each node.

Ensure the `dry_run_config.json` file is updated with the correct server URL and MongoDB URI for each node.

#### HugePages Configuration (No need in current version)

Running multiple nodes requires HugePages to be expanded to accommodate the memory requirements of each node.

Each prover-node requires roughly 15000 hugepages, so ensure the `vm.nr_hugepages` is set to the correct value on the **HOST MACHINE**.

`sudo sysctl -w vm.nr_hugepages=30000` for two nodes, `45000` for three nodes, etc.

Each prover docker need 95GB memory to run.

#### Docker volume and container names

Ensure the docker volumes are unique for each node. This is done by modifying the `docker-compose.yml` file for each node.

The simplest method is to start the containers with a different project name from other directories/containers.

`docker compose -p <node_name> up`, This should start the services in order of mongodb, dry-run-service, prover-node

Where `node` is the custom name of the services you would like to start i.e `node-2`. This is important to separate the containers and volumes from each other.

</details>

## Logs

If you need to follow the logs/output of a specific container,

First navigate to the corresponding directory with the `docker-compose.yml` file.

Then run `docker logs -f <service-name>`

Where `service-name` is the name of the SERVICE named in t he docker compose file (mongodb, prover-node etc.)

If you need to check the static logs of the `prover-dry-run-service`, then please navigate to the corresponding logs volume and view from there.

By default, you can run the following command to list the log files stored and then select one to view the contents.

`sudo ls /var/lib/docker/volumes/prover-node-docker_dry-run-logs-volume/_data -lh`

You can find the latest dry run log file and check the content by : `sudo vim /var/lib/docker/volumes/prover-node-docker_dry-run-logs-volume/_data/[filename.log]`

For prover service log, you can check: (default name configuration)

```
sudo ls /var/lib/docker/volumes/prover-node-docker_prover-logs-volume/_data -lh
sudo vim /var/lib/docker/volumes/prover-node-docker_prover-logs-volume/[filename.log]
```

## Upgrading Prover Node

Upgrading the prover node requires rebuilding the docker image with the new prover node binary, and clearing previously stored data.

Stop all containers with `docker compose down` or `Ctrl+C`.

OR

Manually stop the containers with `docker container ls` and then `docker stop <container-name-or-id>`.

Check docker container status by `docker ps -a`.

Now as we introduce new continuation feature, the prover docker need 58 GB memory to run besides the 15000 huge pages. So totally the machine may need 88 GB memory minimum.

### Pull Latest Changes

Pull the latest changes from the repository with `git pull`.

You may need to stash changes if you have modified the `docker-compose.yml` file and apply them again.

Similarly, if `prover_config.json` or `dry_run_config.json` have been modified, ensure the changes are applied again.

### Run Upgrade Script

Run the upgrade script with `bash scripts/upgrade.sh`.

You should only need to run this each time the prover node is updated.

### Start the Prover Node

Then follow the [Quick Start](#quick-start) steps to start.

If you have already run `scripts/upgrade.sh` and want to start the prover node, you can just run
`bash scripts/start.sh`

## Common issues

1.  If you find the `docker compose up` failed, please do `docker volume rm prover-node-docker_workspace-volume` again and then try `docker compose up` again.
    If it still failed, please check the logs following [Logs](#logs) section

2.  If prover running failed by "memory allocation of xxxx failed" but you had checked and confirmed the avaliable memory is large enough, you can stop the services by `docker compose down` and do `docker volume rm prover-node-docker_workspace-volume` and then start the services by `docker compose up` to see whether it fix the issue or not.

3.  If prover running failed by something related to "Cuda Error", which indicate the docker cannot find cuda or nvidia device, you can try to check `/etc/docker/daemon.json` whether it is correctly set the nvidia runtime. It can be reset by:\
    `sudo nvidia-ctk runtime configure --runtime=docker --set-as-default`\
    `sudo systemctl restart docker` (Ubuntu)\
    and see whether it fix the issue or not.

4.  If prover running failed by some request "Timeout" reason, it maybe some network issue so just try to stop and start docker container again. `docker compose down` and `docker compose up`
