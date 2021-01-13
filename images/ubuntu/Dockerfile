ARG ubuntu_version=18.04

FROM ubuntu:${ubuntu_version}

# Some defaults
ARG UNAME=jenkins
ARG GNAME=jenkins
ARG UID=1000
ARG GID=1000
ARG DEVKIT_URI="https://tcpsbuild.blob.core.windows.net/tcsp-build/OE-CI-devkits-dd4c992d.tar.gz"

# UPDATE EVERYTHING!!!
RUN apt-get update && apt-get upgrade -y

# Install dependencies
RUN apt-get install -y git curl

# Copy over build tools
COPY ./ /
RUN images/scripts/setup.sh

# Install latest released version of open-enclave, this is sourced by some repositories 
RUN apt-get install -y open-enclave

# Add CI emulator for ARM architecture
RUN curl https://tcpsbuild.blob.core.windows.net/tcsp-build/OE-CI-emulator-armtz-aarch64.tar.gz | tar xvz --no-same-permissions --no-same-owner

# Add some tools
RUN groupadd --gid ${GID} ${GNAME} && \
    useradd --create-home --uid ${UID} --gid ${GID} --shell /bin/bash ${UNAME} && \
    curl ${DEVKIT_URI} | tar xvz --no-same-permissions --no-same-owner && \
    echo ${DEVKIT_URI##*/} > /devkits/TARBALL && \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers