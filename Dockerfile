FROM nvidia/cuda:12.2.0-devel-ubuntu22.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
# Install required packages and setup ssh access
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server sudo cmake curl build-essential git wget && rm -rf /var/lib/apt/lists/* \
    && sudo apt update -y && sudo apt install -y apache2-utils \
    && mkdir /var/run/sshd \
    && /etc/init.d/ssh start \
    && useradd -rm -d /home/zkwasm -s /bin/bash -g root -G sudo -u 1001 zkwasm \
    && echo 'zkwasm:zkwasm' | chpasswd \
    && echo 'zkwasm ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

# Switch to the zkwasm user for subsequent commands
USER zkwasm

WORKDIR /home/zkwasm
# Support for cloning from github via https 
RUN git config --global url.https://github.com/.insteadOf git@github.com: 

RUN git clone https://github.com/DelphinusLab/prover-node-release && \
    cd prover-node-release && \
    git checkout 9de90ba9d71878e6229452f8a4ac036805950884

WORKDIR /home/zkwasm/prover-node-release

# Unpack tarball
RUN tar -xvf prover_node_Ubuntu2204.tar

# Create prover log folder
RUN mkdir logs && \
    mkdir logs/prover

WORKDIR /home/zkwasm/prover-node-release
# Command overriden by docker-compose
CMD ["true"]
