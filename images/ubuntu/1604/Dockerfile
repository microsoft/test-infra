FROM ubuntu:16.04

# UPDATE EVERYTHING!!!
RUN apt-get update && apt-get upgrade -y

# Install dependencies
RUN apt-get install -y git

# Copy over build tools
COPY ./ /
RUN images/scripts/setup.sh
