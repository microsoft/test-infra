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
set +vx
set -eo pipefail

## General Azure Configuration ------------

# Azure Service Principal: It is recommended that you create a new one just for Jenkins as the password will be rotated.
readonly AZURE_SERVICE_PRINCIPAL_NAME=""
readonly AZURE_SERVICE_PRINCIPAL_CLIENT_ID=""
readonly AZURE_SERVICE_PRINCIPAL_SUBSCRIPTION_ID=""
readonly AZURE_SERVICE_PRINCIPAL_TENANT=""

# Account used for your Virtual Machine storage
readonly AZURE_VM_STORAGE_ACCOUNT=""

# Resource Group for your Virtual Machines
# Not to be confused with your AKS Resource Group
readonly AZURE_VM_RESOURCE_GROUP=""

# Azure Key Vault URL: It is recommended that you create a new one just for Jenkins to limit the scope of passwords being stored
readonly AZURE_KEYVAULT_URL=""

## Jenkins Configuration ------------------

# Set passwords
# Defaults to a randomly generated password
# For initial runs, a value is required.
# For subsequent runs, set a blank value if no password change is desired

# Jenkins Admin user
readonly JENKINSADMIN_PASSWORD=$(head -c 256 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#%()+=]}|:;,?`' | fold -w 64 | head -n 1)
# oeadmin, a user for SSHing into VM agents
readonly OEADMIN_PASSWORD=$(head -c 256 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#%()+=]}|:;,?`' | fold -w 64 | head -n 1)

# Home directory for the Jenkins master.
# This should not need to change unless you willfully changed the Jenkins home directly elsewhere
readonly JENKINS_HOME=/var/jenkins_home

# ------------END-CONFIGURATION------------

# Get Jenkins Master Pod ID
readonly JENKINS_MASTER_POD=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep jenkins-master | head -n 1)

# Apply configurations
sed -i "s@<AZURE_KEYVAULT_URL>@${AZURE_KEYVAULT_URL}@" configuration/jenkins.yml
sed -i "s/<AZURE_VM_STORAGE_ACCOUNT>/${AZURE_VM_STORAGE_ACCOUNT}/" configuration/clouds.yml
sed -i "s/<AZURE_VM_RESOURCE_GROUP>/${AZURE_VM_RESOURCE_GROUP}/" configuration/clouds.yml

# Apply jenkinsadmin password
if [[ -z ${JENKINSADMIN_PASSWORD:+x} ]]; then
    sed -i "s/<JENKINSADMIN_PASSWORD>/${JENKINSADMIN_PASSWORD}/" configuration/jenkins.yml
fi

# Apply oeadmin password
if [[ -z ${OEADMIN_PASSWORD:+x} ]]; then
    sed -i "s/<OEADMIN_PASSWORD>/${OEADMIN_PASSWORD}/" configuration/jenkins.yml
fi

# Generate UUID for Azure credentials
readonly AZURE_SP_SECRET=$(cat /proc/sys/kernel/random/uuid)

# Change Service Principal Password (assuming it is already created)
az ad sp credential reset --name "${AZURE_SERVICE_PRINCIPAL_NAME}" --password "${AZURE_SP_SECRET}" > /dev/null

# Apply Service Principal secret to configuration
sed -i "s/<AZURE_SP_CLIENT_ID>/${AZURE_SERVICE_PRINCIPAL_CLIENT_ID}/" configuration/jenkins.yml
sed -i "s/<AZURE_SP_SUBSCRIPTION_ID>/${AZURE_SERVICE_PRINCIPAL_SUBSCRIPTION_ID}/" configuration/jenkins.yml
sed -i "s/<AZURE_SP_TENANT>/${AZURE_SERVICE_PRINCIPAL_TENANT}/" configuration/jenkins.yml
sed -i "s/<AZURE_SP_SECRET>/${AZURE_SP_SECRET}/" configuration/jenkins.yml

# Copy in Jenkins configuration to Jenkins master
kubectl exec ${JENKINS_MASTER_POD} -- rm -rf ${JENKINS_HOME}/configuration
kubectl cp configuration ${JENKINS_MASTER_POD}:${JENKINS_HOME}/configuration

# Clean up secrets
sed -i "s/${AZURE_SP_SECRET}/<AZURE_SP_SECRET>/" configuration/jenkins.yml
sed -i "s/${AZURE_SERVICE_PRINCIPAL_CLIENT_ID}/<AZURE_SP_CLIENT_ID>/" configuration/jenkins.yml
sed -i "s/${AZURE_SERVICE_PRINCIPAL_SUBSCRIPTION_ID}/<AZURE_SP_SUBSCRIPTION_ID>/" configuration/jenkins.yml
sed -i "s/${AZURE_SERVICE_PRINCIPAL_TENANT}/<AZURE_SP_TENANT>/" configuration/jenkins.yml
if [[ -z ${OEADMIN_PASSWORD:+x} ]]; then
    sed -i "s/${OEADMIN_PASSWORD}/<OEADMIN_PASSWORD>/" configuration/jenkins.yml
fi
if [[ -z ${JENKINSADMIN_PASSWORD:+x} ]]; then
    sed -i "s/${JENKINSADMIN_PASSWORD}/<JENKINSADMIN_PASSWORD>/" configuration/jenkins.yml
fi

# Clean up configuration
sed -i "s@${AZURE_KEYVAULT_URL}@<AZURE_KEYVAULT_URL>@" configuration/jenkins.yml
sed -i "s/${AZURE_VM_STORAGE_ACCOUNT}/<AZURE_VM_STORAGE_ACCOUNT>/" configuration/clouds.yml
sed -i "s/${AZURE_VM_RESOURCE_GROUP}/<AZURE_VM_RESOURCE_GROUP>/" configuration/clouds.yml

echo "Configuration complete.
The Jenkins administrator credentials are below. Please store this somewhere secure for your records.
User: jenkinsadmin
Password: ${JENKINSADMIN_PASSWORD}"