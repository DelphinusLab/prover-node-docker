# Prover Node Docker

This is the docker container for the prover node. This container is responsible for running the prover node and handling tasks from the server.

## Table of Contents

- [Quick Start](#quick-start)
- [Environment Setup](#environment)
  - [Setting up the Host Machine](#setting-up-the-host-machine)
- [Building](#building)
  - [Build the Docker Image](#build-the-docker-image)
- [Running](#running)
  - [Prover Node Configuration](#prover-node-configuration)
  - [Dry Run Service Configuration](#dry-run-service-configuration)
  - [HugePages Configuration](#hugepages-configuration)
  - [GPU Configuration](#gpu-configuration)
  - [Multiple Nodes on the same machine](#multiple-nodes-on-the-same-machine)
- [Logs](#logs)
- [Upgrading Prover Node Detail](#upgrading-prover-node-detail)

## Quick Start

### Upgrade prover node

If you had run the prover node services and just want to upgrade to new version, here is the simple steps:

`git stash; git pull; git stash pop` to update to the latest version. Resolve the conflict if have.

#### Special notes for this upgrading: for dry_run_config.json need remove the mongodb_uri as we never use mongodb anymore.

`bash scripts/stop.sh` to stop all running prover node docker services

`bash scripts/upgrade.sh` to clean env files.

`bash scripts/start.sh` to start the prover node docker services

#### How to restart

If the docker container accidently stopped by some reason like ctrl-C or machine restarted, and no need upgrade. Just need run `bash scripts/start.sh` to start them again.

#### Tips:

If you accidentally have the db init failed and want to clean the db volume and re-upgrade, you can just do `bash scripts/stop.sh`, `bash scripts/upgrade_full_clean.sh`, `bash scripts/start.sh` to full clean volumes and restart the services.

### Setup new prover node

If this is first time to run the prover node services on the node:

Make sure you had reviewed the [Environment Setup](#environment) to setup the node environment.

Make sure you had reviewed the [Prover Node Configuration](#prover-node-configuration) part and changed the config files.

`bash scripts/build_image.sh` to build the prover node docker image.

`bash scripts/start.sh` to start the prover node docker services.

### Configuring monitoring and alerts

The monitor service runs alongside the other docker services and send alerts to an internal slack channel. The following variables, located in the [.env file](./scripts/.env), are required to be configured for the monitor service:

- `CONTAINER_NAMES`: these must be set to the docker containers to be monitored, if default configuration is being used then these don't need to be changed.
- `ALERT_POST_URL`: if you don't required monitoring service, then this can be left empty and the service won't start, otherwise, please contact the Delphinus team and the url will be generated for you. Do not share this publicly.

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
- prover-node-release #11bd77a4933fa4d289627e2b3e5d7e8be58a565f

The versions should not be changed unless the prover node is updated. The compiled prover node binary is sensitive to the CUDA version and the Ubuntu version.

### Build the Docker Image

Better clean the old docker image/volumes if you want.

To Build the docker image, run the following command in the root directory of the repository.

`bash scripts/build_image.sh`

We do not use BuildKit as there are issues with the CUDA runtime and BuildKit.

## Running

### Prover Node Configuration

`prover_config.json` file is the config file for prover node service.

- `server_url` - The URL of the server to connect to for tasks. Currently the public test server's rpc is "https://rpc.zkwasmhub.com".
- `priv_key` - The private key of the prover node. This is used to sign the tasks which were done by the prover node. If you want to start multiple prover nodes, please use different priv key for each node as it will represent your node. <mark>**Please note do not add "0x" at the begining of priv.**</mark>

### Dry Run Service Configuration

The Dry Run service will be required to run parallel to the prover node. The Dry Run service is responsible for synchronising tasks with the server and ensuring the prover node is working correctly.
This service must be run in parallel to the prover node, so running the service through docker compose is recommended.

`dry_run_config.json` file is the config file for prover dry run service, modify the connection strings to the server.

- `server_url` - The URL of the server to connect to for tasks. Ensure this is the same as the prover node. Currently the public test server's rpc is "https://rpc.zkwasmhub.com".

`docker compose up` and use default `docker-compose.yml`.

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

</details>

## Multiple Prover Nodes

### Multiple Nodes on the same machine

<details>
  <summary>Details</summary>

We do not recommand to run multiple nodes on the same machine but if you really want to do that, here is some help info.

To run multiple prover nodes on the same machine, it is recommended to clone the repository and modify the required files.

- `docker-compose.yml`
- `prover-node-config.json`
- `dry_run_config.json`

There are a few things to consider when running multiple nodes on the same machine.

- GPU
- Config file information
- Docker volume and container names

#### GPU

Ensure the GPU's are specified in the `docker-compose.yml` file for each node.
It is crucial that each GPU is only used ONCE otherwise you may encounter out of memory errors.
We recommend to set the `device_ids` field where you can specify the GPU to use in each `docker-compose.yml` file.

As mentioned, use `nvidia-smi` to check the GPU index and ensure the `device_ids` field is set correctly and uniquely.

#### Config file information

Ensure the `prover-config.json` file is updated with the correct server URL and private key for each node.

Private key should be UNIQUE for each node.

Ensure the `dry_run_config.json` file is updated with the correct server URL for each node.

#### HugePages Configuration (No need in current version)

Running multiple nodes requires HugePages to be expanded to accommodate the memory requirements of each node.

Each prover-node requires roughly 15000 hugepages, so ensure the `vm.nr_hugepages` is set to the correct value on the **HOST MACHINE**.

`sudo sysctl -w vm.nr_hugepages=30000` for two nodes, `45000` for three nodes, etc.

Each prover docker need 120GB memory to run.

#### Docker volume and container names

Ensure the docker volumes are unique for each node. This is done by modifying the `docker-compose.yml` file for each node.

The simplest method is to start the containers with a different project name from other directories/containers.

`docker compose -p <node_name> up`, This should start the services in order of dry-run-service, prover-node

Where `node` is the custom name of the services you would like to start i.e `node-2`. This is important to separate the containers and volumes from each other.

</details>

## Logs

If you need to follow the logs/output of a specific container,

First navigate to the corresponding directory with the `docker-compose.yml` file.

Then run `docker logs -f <service-name>`

Where `service-name` is the name of the SERVICE named in t he docker compose file (prover-node etc.)

Example:

Prover node logs

```
docker compose logs -f prover-node --tail 100
```

Prover dry run logs

```
docker compose logs -f prover-dry-run-service --tail 100
```

If you need to check the static logs of the `prover-dry-run-service`, then please navigate to the corresponding logs volume and view from there.

By default, you can run the following command to list the log files stored and then select one to view the contents.

`sudo ls /var/lib/docker/volumes/prover-node-docker_dry-run-logs-volume/_data -lh`

You can find the latest dry run log file and check the content by : `sudo vim /var/lib/docker/volumes/prover-node-docker_dry-run-logs-volume/_data/[filename.log]`

For prover service log, you can check: (default name configuration)

```
sudo ls /var/lib/docker/volumes/prover-node-docker_prover-logs-volume/_data -lh
sudo vim /var/lib/docker/volumes/prover-node-docker_prover-logs-volume/[filename.log]
```

## Upgrading Prover Node Detail

### Stop Prover Node

Upgrading the prover node requires rebuilding the docker image with the new prover node binary, and clearing previously stored data.

Stop all containers with `docker compose down`, `Ctrl+C` or `bash scripts/stop.sh` if using the default project name.

OR

Manually stop ALL containers with `docker container ls` and then `docker stop <container-name-or-id>`.

Check docker container status by `docker ps -a`.

Please note: Please manually double check and confirm the `ftp docker container` are stopped if it was started manually in old version.

Now as we introduce new continuation and auto feature, the prover docker need 80 GB memory to run besides the 15000 huge pages. So totally the machine may need 120 GB memory.

### Pull Latest Changes

Pull the latest changes from the repository with `git pull`.

You may need to stash changes if you have modified the `docker-compose.yml` file and apply them again.

Similarly, if `prover_config.json` or `dry_run_config.json` have been modified, ensure the changes are applied again.

### Run Upgrade Script

Run the upgrade script with `bash scripts/upgrade.sh`.

You should only need to run this each time the prover node is updated.

### Start the Prover Node

Just run

`bash scripts/start.sh`

First time starting after upgrading need download the new merkle db from docker hub so it will take times based on download speed.
Also it need load 15GB checkpoint merkle db into database so it may take time for the first starting after upgrading.

Tips:
If you accidentally have the db init failed and want to clean the db volume and re-upgrade, you can just do `bash scripts/stop.sh`, `bash scripts/upgrade_full_clean.sh`, `bash scripts/start.sh` to full clean volumes and restart the services.

## Common issues

1.  If you find the `bash scripts/start.sh` failed, please check the error to see wether it related to machine environement. If still cannot get the reason, you can do `docker volume rm prover-node-docker_workspace-volume` and `bash scripts/start.sh` again to try.
    If it still failed, please check the logs following [Logs](#logs) section

2.  If prover running failed by "memory allocation of xxxx failed" but you had checked and confirmed the avaliable memory is large enough, you can stop the services by `bash scripts/stop.sh` and do `docker volume rm prover-node-docker_workspace-volume` and then start the services by `bash scripts/start.sh` to see whether it fix the issue or not.

3.  If prover running failed by something related to "Cuda Error", which indicate the docker cannot find cuda or nvidia device, you can try to check `/etc/docker/daemon.json` whether it is correctly set the nvidia runtime. It can be reset by:\
    `sudo nvidia-ctk runtime configure --runtime=docker --set-as-default`\
    `sudo systemctl restart docker` (Ubuntu)\
    and then stop and start the service again by `bash scripts/stop.sh` and `bash scripts/start.sh` see whether it fix the issue or not.
