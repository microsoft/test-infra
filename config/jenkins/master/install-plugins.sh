#!/usr/bin/env bash
set -eox pipefail

#
# Install the list of saved plugins
#
DIR=$(dirname $0)
docker exec -e REF=/var/jenkins_home jenkins /usr/local/bin/install-plugins.sh $(cat $DIR/plugins.txt)
systemctl restart jenkins
