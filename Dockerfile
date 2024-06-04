FROM nvidia/cuda:12.2.0-devel-ubuntu22.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
# Install required packages and setup ssh access
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server sudo cmake curl build-essential git && rm -rf /var/lib/apt/lists/* \
    && sudo apt update -y && sudo apt install -y apache2-utils \
    && mkdir /var/run/sshd \
    && /etc/init.d/ssh start \
    && useradd -rm -d /home/zkwasm -s /bin/bash -g root -G sudo -u 1001 zkwasm \
    && echo 'zkwasm:zkwasm' | chpasswd \
    && echo 'zkwasm ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

# Installing mongo DB
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime \
    && echo "Etc/UTC" > /etc/timezone \
    && sudo apt-get install gnupg curl \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && sudo apt-get update \
    && sudo apt-get install -y mongodb-org

# Switch to the zkwasm user for subsequent commands
USER zkwasm

WORKDIR /home/zkwasm
# Support for cloning from github via https 
RUN git config --global url.https://github.com/.insteadOf git@github.com: 

RUN git clone https://github.com/DelphinusLab/prover-node-release && \
    cd prover-node-release && \
    git checkout f2d2ffc6154dff58343bef325f1be8e1d234a4cf

WORKDIR /home/zkwasm/prover-node-release

# Unpack tarball
RUN tar -xvf prover_node_Ubuntu2204.tar

# Create prover log folder
RUN mkdir logs && \
    mkdir logs/prover

WORKDIR /home/zkwasm/prover-node-release
# Run the start script
CMD bash start_prover.sh
