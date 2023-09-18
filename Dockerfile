FROM nvidia/cuda:12.2.0-devel-ubuntu20.04
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
ENV PATH="/home/zkwasm/.cargo/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain nightly -y 

WORKDIR /home/zkwasm
# Support for cloning from github via https for submodules (wasmi) and download zkWasm repo
RUN git config --global url.https://github.com/.insteadOf git@github.com: && \
    git clone https://github.com/DelphinusLab/zkWasm.git && \
    cd zkWasm && \
    git checkout 738bdb7d23b8c67ab62203884d1dce207d3e920b && \
    git submodule sync && \
    git submodule update --init --recursive

WORKDIR /home/zkwasm/zkWasm
RUN cargo build --release --features cuda 

# Install solidity compiler
WORKDIR /home/zkwasm
RUN sudo apt-get update && \
    sudo apt-get install -y software-properties-common && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo add-apt-repository ppa:ethereum/ethereum && \
    sudo apt-get update && \
    sudo apt-get install solc -y

RUN git clone https://github.com/DelphinusLab/prover-node-release && \
    cd prover-node-release && \
    git checkout 048fa7c74a3386119aaaa0b55b4eff38fea54f27

WORKDIR /home/zkwasm/prover-node-release

# Unpack tarball
RUN tar -xvf prover_node_Ubuntu2004.tar

# Create prover log folder
RUN mkdir logs && \
    mkdir logs/prover

# Install Node.js
RUN sudo apt-get update && \
    sudo apt-get install -y ca-certificates curl gnupg && \
    sudo mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list && \
    sudo apt-get update && \
    sudo apt-get install -y nodejs

# currently sudo install with user seems best. Some trouble installing some packages as root
RUN sudo npm install -g truffle

# npm install deploy packages
WORKDIR /home/zkwasm/prover-node-release/deploy
RUN sudo npm install

WORKDIR /home/zkwasm/prover-node-release
# Run the start script
CMD bash start_prover.sh
