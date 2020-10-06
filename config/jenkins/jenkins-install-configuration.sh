#!/usr/bin/env bash
#
# This is used to apply configuration to the Jenkins master.
# Should be ran after plugins are installed on the Jenkins master OR if configuration needs to be updated
#
# Instructions:
#   1. Update the configuration variables in the section below.
#   2. chmod +x ./jenkins-install-configuration.sh
#   3. ./jenkins-install-configuration.sh
#
# -----------BEGIN-CONFIGURATION-----------
set +x
set -eo pipefail

## General Azure Configuration
# Azure Service Principal: It is recommended that you create a new one just for Jenkins as the password will be rotated.
readonly SERVICE_PRINCIPAL_NAME="http://${USER}-jenkins-test1"
readonly SERVICE_PRINCIPAL_ID=""
readonly SERVICE_PRINCIPAL_SUBSCRIPTION=""
readonly SERVICE_PRINCIPAL_TENANT=""

# Azure Key Vault URL: It is recommended that you create a new one just for Jenkins to limit the scope of passwords being stored
readonly AZURE_KEYVAULT_URL="https://cyan-keyvault-test-vault.vault.azure.net/"

# Home directory for the Jenkins master.
# This should not need to change unless you willfully changed the Jenkins home directly elsewhere
readonly JENKINS_HOME=/var/jenkins_home

# ------------END-CONFIGURATION------------

# Get Jenkins Master Pod ID
readonly JENKINS_MASTER_POD=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep jenkins-master | head -n 1)

# Apply Key Vault url
sed -i "s@<AZURE_KEYVAULT_URL>@${AZURE_KEYVAULT_URL}@" configuration/jenkins.yml

# Create and apply oeadmin password
readonly OEADMIN_PASSWORD=$(head -c 256 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#%()+=]}|:;,?`' | fold -w 64 | head -n 1)
sed -i "s/<OEADMIN_PASSWORD>/${OEADMIN_PASSWORD}/" configuration/jenkins.yml

# Generate UUID for Azure credentials
readonly AZURE_SP_SECRET=$(cat /proc/sys/kernel/random/uuid)

# Change Service Principal Password (assuming it is already created)
az ad sp credential reset --name "${SERVICE_PRINCIPAL_NAME}" --password "${AZURE_SP_SECRET}" > /dev/null

# Apply Service Principal secret to configuration
sed -i "s@<AZURE_SP_CLIENT>@${SERVICE_PRINCIPAL_ID}@" configuration/jenkins.yml
sed -i "s@<AZURE_SP_SUBSCRIPTION>@${SERVICE_PRINCIPAL_SUBSCRIPTION}@" configuration/jenkins.yml
sed -i "s@<AZURE_SP_TENANT>@${SERVICE_PRINCIPAL_TENANT}@" configuration/jenkins.yml
sed -i "s/<AZURE_SP_SECRET>/${AZURE_SP_SECRET}/" configuration/jenkins.yml

# Copy in Jenkins configuration to Jenkins master
kubectl exec ${JENKINS_MASTER_POD} -- rm -rf ${JENKINS_HOME}/configuration
kubectl cp configuration ${JENKINS_MASTER_POD}:${JENKINS_HOME}/configuration

# Clean up secrets
sed -i "s/${AZURE_SP_SECRET}/<AZURE_SP_SECRET>/" configuration/jenkins.yml
sed -i "s/${OEADMIN_PASSWORD}/<OEADMIN_PASSWORD>/" configuration/jenkins.yml
sed -i "s@${AZURE_KEYVAULT_URL}@<AZURE_KEYVAULT_URL>@" configuration/jenkins.yml
