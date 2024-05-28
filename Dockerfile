FROM nvidia/cuda:12.2.0-devel-ubuntu22.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
# Install required packages and setup ssh access
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server sudo cmake curl build-essential git && rm -rf /var/lib/apt/lists/* \
    && mkdir /var/run/sshd \
    && /etc/init.d/ssh start \
    && useradd -rm -d /home/zkwasm -s /bin/bash -g root -G sudo -u 1001 zkwasm \
    && echo 'zkwasm:zkwasm' | chpasswd \
    && echo 'zkwasm ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

# Switch to the zkwasm user for subsequent commands
USER zkwasm

# Install Rust toolchain 
# ENV PATH="/home/zkwasm/.cargo/bin:${PATH}"
# RUN curl https://sh.rustup.rs -sSf | \
#     sh -s -- --default-toolchain nightly -y 

WORKDIR /home/zkwasm
# Support for cloning from github via https 
RUN git config --global url.https://github.com/.insteadOf git@github.com: 

# Install solidity compiler
WORKDIR /home/zkwasm
RUN sudo apt-get update && \
    sudo apt-get install -y software-properties-common && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo add-apt-repository ppa:ethereum/ethereum && \
    sudo apt-get update && \
    sudo apt-get install solc -y && \
    sudo apt update -y && sudo apt install -y apache2-utils

RUN git clone https://github.com/DelphinusLab/prover-node-release && \
    cd prover-node-release && \
    git checkout zkwas-274

WORKDIR /home/zkwasm/prover-node-release

# Unpack tarball
RUN tar -xvf prover_node_Ubuntu2204.tar

# Create prover log folder
RUN mkdir logs && \
    mkdir logs/prover

WORKDIR /home/zkwasm/prover-node-release
# Run the start script
CMD bash start_prover.sh
