#! /usr/bin/env bash
#
# Creates a new AKS cluster to host the Jenkins service.
#
# Instructions:
#   1. Set a new resource group in the section below
#   2. Modify the remaining variables with your own in the section below
#   3. Run this script without any options. Use -c option if you want to update the configuration only.
#
set +vx
set -eo pipefail

# -----------BEGIN-CONFIGURATION-----------

## General Azure Configuration ------------

# Resource group to hold AKS resources
# Important: use a *new* resource group! This script will delete the resource group if it exists.
readonly AZURE_RESOURCE_GROUP=""

# Azure region code.
# Must be a region that supports ACC. E.g. "eastus", "canadacentral", "uksouth"
# To list all region codes use: `az account list-locations -o table`
readonly AZURE_LOCATION=""

# This controls the URL that would be used to access the Jenkins master
# E.g. prow-jenkins-test would result in the url https://prow-jenkins-test.eastus.cloudapp.azure.com/
readonly DNS_LABEL=""

## AKS Configurations ---------------------

# Name your AKS cluster
readonly AKS_CLUSTER_NAME=""

# Name your reserved public ip resource
readonly AKS_PUBLIC_IP_NAME=""

# Choose the node size used to host Jenkins
# At least 8 cores and 16 GB is recommended. 
# For other node sizes, see: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
readonly AKS_NODE_SIZE="Standard_D8_v3"
# Only 2 nodes are usually used to host Jenkins, ingress, and supporting services
readonly AKS_MIN_NODE_COUNT="1"
readonly AKS_MAX_NODE_COUNT="10"

# Version of kubernetes to use on AKS.
# For list of versions, see: https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions
# It is recommended you use the the same Kubectl version as your AKS Kubernetes version
readonly AKS_KUBERNETES_VERSION=1.18.8

## Azure VMs (Jenkins Workers) ------------

# Name the new resource group that will contain your Virtual Machines
# Not to be confused with your AKS Resource Group
# Create this manually if you do not want to grant your Jenkins Service Principal the
# permissions to create new resource groups in the subscription. Otherwise this 
# resource group will be automatically created by Jenkins.
readonly AZURE_VM_RESOURCE_GROUP=""

# Location used for all your Azure VMs. See cloud.yml for more fine grained control if necessary.
# This uses the common name of regions. Example: "East US", "Canada Central", "UK South"
# To list all region codes use: `az account list-locations -o table`
readonly AZURE_VM_LOCATION=""

# Azure VM Image Gallery that contains the necessary VM images for workers
readonly AZURE_VM_GALLERY_NAME=""
readonly AZURE_VM_GALLERY_RESOURCE_GROUP=""
readonly AZURE_VM_GALLERY_SUBSCRIPTION_ID=""

## Let's Encrypt Configuration ------------
# Email to be used as a Let's Encrypt account
readonly LETSENCRYPT_EMAIL=""

## Jenkins Secrets ------------------------

# If any secrets need to be changed after the initial run, with the exception of jenkinsadmin, you must delete the secret with kubectl first.

# Jenkins Admin user password is initially set via this configuration.
# Subsequent password changes need to be done through the Jenkins UI
readonly JENKINSADMIN_PASSWORD=$(head -c 256 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#%()+=]}|:;,?`' | fold -w 64 | head -n 1)

# Jenkins credentials for agents. oeadmin is the user for SSHing into VM agents
# Must only have a-z, A-Z, 0-9, or the following symbols: ~!@#%()+=]}|:;,?`
readonly OEADMIN_PASSWORD=$(head -c 256 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#%()+=]}|:;,?`' | fold -w 64 | head -n 1)

# Remote trigger token for remotely triggering jobs to run
# Must only have a-z, A-Z, 0-9, or the following symbols: ~_-
readonly JENKINS_REMOTE_TRIGGER_TOKEN=$(head -c 256 /dev/urandom | tr -dc 'a-zA-Z0-9~_-' | fold -w 64 | head -n 1)

## Jenkins Configuration ------------------

# Jenkins Admin email
readonly JENKINSADMIN_EMAIL="nobody@nowhere.com"

# Home directory for the Jenkins master. This should not need to change unless you willfully changed the Jenkins home directly elsewhere
readonly JENKINS_HOME=/var/jenkins_home

# Azure Key Vault URL
# It is recommended that you create a new one just for Jenkins to limit the scope of passwords being stored
readonly AZURE_KEYVAULT_URL=""

# Jenkins Azure Service Principal
# This is used to access the Azure Key Vault and create Azure VMs
# It is recommended that you create a new one just for Jenkins as the password will be rotated.
# Permissions:
#   1) access policy to the Key Vault
#   2) assign a role to manage resources at either the subscription level or the resource group set for "AZURE_VM_RESOURCE_GROUP"
#   3) access to the image gallery used in the Azure Cloud VM configuration seen in configuration/clouds.yml
readonly AZURE_SERVICE_PRINCIPAL_NAME=""
readonly AZURE_SERVICE_PRINCIPAL_CLIENT_ID=""
readonly AZURE_SERVICE_PRINCIPAL_SUBSCRIPTION_ID=""
readonly AZURE_SERVICE_PRINCIPAL_TENANT_ID=""
readonly AZURE_SERVICE_PRINCIPAL_SECRET=$(cat /proc/sys/kernel/random/uuid)

# ------------END-CONFIGURATION------------

readonly BASEDIR=$(dirname "$0")

# Functions -------------------------------

deploy_aks () {

  az account set --subscription ${AZURE_SERVICE_PRINCIPAL_SUBSCRIPTION_ID}

  # Create a service principal
  AKS_SP_ID=$(az ad sp create-for-rbac --name http://${AKS_CLUSTER_NAME}-sp --query appId | sed 's/"//g')
  echo ${AKS_SP_ID}

  # Retrieve service principal secret
  AKS_SP_SECRET=$(az ad sp credential reset --name http://${AKS_CLUSTER_NAME}-sp --query password | sed 's/"//g')
  echo ${AKS_SP_SECRET}
  
  # Delete resource group if exists
  if [[ $(az group show --name ${AZURE_RESOURCE_GROUP}) ]]; then
    read -p "Resource group "${AZURE_RESOURCE_GROUP}" exists. Are you ready to delete it and recreate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      az group delete --name ${AZURE_RESOURCE_GROUP} --yes
    else
      echo "[Error] Please start with a new resource group, or be ready to delete the existing resource group."
      exit 1
    fi
  fi

  # Create resource group
  az group create --location ${AZURE_LOCATION} --name ${AZURE_RESOURCE_GROUP}

  # Create AKS Cluster
  az aks create \
    --resource-group ${AZURE_RESOURCE_GROUP} \
    --name ${AKS_CLUSTER_NAME} \
    --service-principal ${AKS_SP_ID} \
    --client-secret ${AKS_SP_SECRET} \
    --node-vm-size ${AKS_NODE_SIZE} \
    --vm-set-type VirtualMachineScaleSets \
    --load-balancer-sku standard \
    --location ${AZURE_LOCATION} \
    --enable-cluster-autoscaler \
    --min-count ${AKS_MIN_NODE_COUNT} \
    --max-count ${AKS_MAX_NODE_COUNT} \
    --no-ssh-key \
    --kubernetes-version ${AKS_KUBERNETES_VERSION}

  # Get AKS Credentials
  az aks get-credentials --resource-group ${AZURE_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --overwrite-existing
}


deploy_jenkins_ingress () {

  # Apply Ingress configuration
  sed -i "s/<LETSENCRYPT_EMAIL>/${LETSENCRYPT_EMAIL}/" ${BASEDIR}/kubernetes/jenkins-ingress.yml
  sed -i "s/<DNS_LABEL>/${DNS_LABEL}/" ${BASEDIR}/kubernetes/jenkins-ingress.yml
  sed -i "s/<AZURE_LOCATION>/${AZURE_LOCATION}/" ${BASEDIR}/kubernetes/jenkins-ingress.yml

  # Create a namespace for your ingress resource
  if ! kubectl get namespace ingress; then
    kubectl create namespace ingress
  fi

  # Add the official stable and ingress-nginx repos
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo add stable https://charts.helm.sh/stable
  helm repo update

  # Get AKS Resource Group Name
  readonly AKS_RESOURCE_GROUP=$(az aks show --resource-group ${AZURE_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --query nodeResourceGroup -o tsv)

  # Assign Static IP
  readonly STATIC_IP=$(az network public-ip create --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_PUBLIC_IP_NAME} --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv --dns-name ${DNS_LABEL})

  # Use Helm to deploy an NGINX ingress controller
  # Possible parameters reference: https://github.com/kubernetes/ingress-nginx/blob/master/charts/ingress-nginx/values.yaml
  # Node labels for controller and backend pod assignment
  # Ref: https://kubernetes.io/docs/user-guide/node-selection/
  helm install nginx ingress-nginx/ingress-nginx \
      --namespace ingress \
      --set controller.replicaCount=2 \
      --set controller.service.loadBalancerIP="${STATIC_IP}" \
      --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
      --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux

  # Label the cert-manager namespace to disable resource validation
  kubectl label namespace ingress cert-manager.io/disable-validation=true

  # Add the Jetstack Helm repository
  helm repo add jetstack https://charts.jetstack.io
  helm repo update

  # Install the cert-manager Helm chart
  helm install \
    cert-manager \
    --namespace ingress \
    --version v1.1.0 \
    --set installCRDs=true \
    --set nodeSelector."beta\.kubernetes\.io/os"=linux \
    jetstack/cert-manager

  kubectl wait --for=condition=ready pod -l app=webhook --timeout=2m -n ingress

  # Needs to retry several times due to webhook api not being ready to process requests
  while ! kubectl apply -f ${BASEDIR}/kubernetes/jenkins-ingress.yml; do
    kubectl delete -f ${BASEDIR}/kubernetes/jenkins-ingress.yml || true
    sleep 10
  done

  # Clean up configuration locally in case anything changes in subsequent runs.
  sed -i "s/${LETSENCRYPT_EMAIL}/<LETSENCRYPT_EMAIL>/" ${BASEDIR}/kubernetes/jenkins-ingress.yml
  sed -i "s/${DNS_LABEL}/<DNS_LABEL>/" ${BASEDIR}/kubernetes/jenkins-ingress.yml
  sed -i "s/${AZURE_LOCATION}/<AZURE_LOCATION>/" ${BASEDIR}/kubernetes/jenkins-ingress.yml
}


deploy_jenkins () {

  # Add jenkinsadmin password
  if  ! kubectl get secret jenkinsadmin; then
    kubectl create secret generic jenkinsadmin --from-literal=password="${JENKINSADMIN_PASSWORD}"
  fi

  # Add oeadmin password
  if ! kubectl get secret oeadmin; then
    kubectl create secret generic oeadmin --from-literal=password="${OEADMIN_PASSWORD}"
  fi

  # Add Jenkins remote trigger token for all jobs
  if ! kubectl get secret jenkinsremotetrigger; then
    kubectl create secret generic jenkinsremotetrigger --from-literal=password="${JENKINS_REMOTE_TRIGGER_TOKEN}"
  fi

  # Apply Key Vault Service Principal within pod
  if ! kubectl get secret jenkinssp; then
    # Set secret. If it fails to change the SP, make sure it exists and you have permissions to manage it.
    az ad sp credential reset --name "${AZURE_SERVICE_PRINCIPAL_NAME}" --password "${AZURE_SERVICE_PRINCIPAL_SECRET}"
    kubectl create secret generic jenkinssp \
      --from-literal=clientid="${AZURE_SERVICE_PRINCIPAL_CLIENT_ID}" \
      --from-literal=subscriptionid="${AZURE_SERVICE_PRINCIPAL_SUBSCRIPTION_ID}" \
      --from-literal=tenantid="${AZURE_SERVICE_PRINCIPAL_TENANT_ID}" \
      --from-literal=secret="${AZURE_SERVICE_PRINCIPAL_SECRET}"
  fi

  # Deploy jenkins-master
  kubectl apply -f ${BASEDIR}/kubernetes/jenkins-master-deployment.yml
  sleep 3

  # Get Jenkins Master Pod ID
  readonly JENKINS_MASTER_POD=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep jenkins-master | head -n 1)

  # Wait for pod to be ready to accept commands
  sleep 5
  kubectl wait --for=condition=available deployment/jenkins-master --timeout=15m

  # Apply workaround for https://github.com/jenkinsci/docker/issues/399
  kubectl exec ${JENKINS_MASTER_POD} -- ln -fs /dev/null ${JENKINS_HOME}/.owners
}


configure_jenkins () {

  if [[ -z ${JENKINS_MASTER_POD+x} ]]; then
    readonly JENKINS_MASTER_POD=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep jenkins-master | head -n 1)
  fi

  # Copy in Jenkins configuration to Jenkins master
  kubectl exec ${JENKINS_MASTER_POD} -- rm -rf ${JENKINS_HOME}/configuration
  kubectl cp configuration ${JENKINS_MASTER_POD}:${JENKINS_HOME}/configuration

  # Apply general configurations
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s/<JENKINSADMIN_EMAIL>/${JENKINSADMIN_EMAIL}/" ${JENKINS_HOME}/configuration/jenkins.yml
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s@<AZURE_KEYVAULT_URL>@${AZURE_KEYVAULT_URL}@" ${JENKINS_HOME}/configuration/jenkins.yml
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s/<DNS_LABAEL>/${DNS_LABEL}/" ${JENKINS_HOME}/configuration/jenkins.yml
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s/<AZURE_LOCATION>/${AZURE_LOCATION}/" ${JENKINS_HOME}/configuration/jenkins.yml
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s/<AZURE_VM_RESOURCE_GROUP>/${AZURE_VM_RESOURCE_GROUP}/" ${JENKINS_HOME}/configuration/clouds.yml
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s/<AZURE_VM_LOCATION>/${AZURE_VM_LOCATION}/" ${JENKINS_HOME}/configuration/clouds.yml
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s/<AZURE_VM_GALLERY_NAME>/${AZURE_VM_GALLERY_NAME}/" ${JENKINS_HOME}/configuration/clouds.yml
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s/<AZURE_VM_GALLERY_RESOURCE_GROUP>/${AZURE_VM_GALLERY_RESOURCE_GROUP}/" ${JENKINS_HOME}/configuration/clouds.yml
  kubectl exec ${JENKINS_MASTER_POD} -- sed -i "s/<AZURE_VM_GALLERY_SUBSCRIPTION_ID>/${AZURE_VM_GALLERY_SUBSCRIPTION_ID}/" ${JENKINS_HOME}/configuration/clouds.yml
  
  # Apply secrets within pod
  kubectl exec ${JENKINS_MASTER_POD} -- sh -c 'sed -i "s/<JENKINSADMIN_PASSWORD>/${SECRET_JENKINSADMIN_PASSWORD}/" ${JENKINS_HOME}/configuration/jenkins.yml'
  kubectl exec ${JENKINS_MASTER_POD} -- sh -c 'sed -i "s/<OEADMIN_PASSWORD>/${SECRET_OEADMIN_PASSWORD}/" ${JENKINS_HOME}/configuration/jenkins.yml'
  kubectl exec ${JENKINS_MASTER_POD} -- sh -c 'sed -i "s/<AZURE_SP_CLIENT_ID>/${SECRET_AZURE_SERVICE_PRINCIPAL_CLIENT_ID}/" ${JENKINS_HOME}/configuration/jenkins.yml'
  kubectl exec ${JENKINS_MASTER_POD} -- sh -c 'sed -i "s/<AZURE_SP_SUBSCRIPTION_ID>/${SECRET_AZURE_SERVICE_PRINCIPAL_SUBSCRIPTION_ID}/" ${JENKINS_HOME}/configuration/jenkins.yml'
  kubectl exec ${JENKINS_MASTER_POD} -- sh -c 'sed -i "s/<AZURE_SP_TENANT_ID>/${SECRET_AZURE_SERVICE_PRINCIPAL_TENANT_ID}/" ${JENKINS_HOME}/configuration/jenkins.yml'
  kubectl exec ${JENKINS_MASTER_POD} -- sh -c 'sed -i "s/<AZURE_SP_SECRET>/${SECRET_AZURE_SERVICE_PRINCIPAL_SECRET}/" ${JENKINS_HOME}/configuration/jenkins.yml'
  kubectl exec ${JENKINS_MASTER_POD} -- sh -c 'find ${JENKINS_HOME}/configuration/jobs -type f -name "*.yml" -exec sed -i "s/<JENKINS_REMOTE_TRIGGER_TOKEN>/${SECRET_JENKINS_REMOTE_TRIGGER_TOKEN}/" {} +'
}


install_jenkins_plugins () {

  if [[ -z ${JENKINS_MASTER_POD+x} ]]; then
    readonly JENKINS_MASTER_POD=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep jenkins-master | head -n 1)
  fi

  # Copy plugins list and install
  kubectl cp plugins.txt ${JENKINS_MASTER_POD}:${JENKINS_HOME}
  kubectl exec ${JENKINS_MASTER_POD} -- jenkins-plugin-cli --plugin-file ${JENKINS_HOME}/plugins.txt --plugin-download-directory ${JENKINS_HOME}/plugins/

  read -p "Plugins installed. Do you want to automatically do a rolling restart of Jenkins to apply the changes? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # This creates a new pod and terminates the currently running pod, so plugins are reloaded.
    echo "Waiting for first pod to be ready to avoid conflicts..."
    kubectl wait --for=condition=ready pod -l app=jenkins-master --timeout=30m
    kubectl patch deployment jenkins-master -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"$(date +%s)\"}}}}}"
  fi
}

print_info () {

  # Determine FQDN
  readonly JENKINS_FQDN=$(az network public-ip list --resource-group ${AKS_RESOURCE_GROUP} --query "[?name=='${AKS_PUBLIC_IP_NAME}'].[dnsSettings.fqdn]" -o tsv)

  echo "
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  Please store this somewhere secure for your records.
  URL: https://${JENKINS_FQDN}
  Jenkins Admin User: jenkinsadmin
  Password: ${JENKINSADMIN_PASSWORD}
  To recover the password, use:
  kubectl get secret jenkinsadmin -o jsonpath='{.data.password}' | base64 --decode
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
}

# Main -----------------------------------

while getopts ":pc" opt; do
  case ${opt} in
    c ) echo "Skipping installation and updating jenkins-master configuration only..."
        configure_jenkins
        echo "Configuration completed. Please reload Jenkins through Manage Jenkins > Configuration as Code"
        exit 0
        ;;
    p ) echo "Installing Jenkins plugins..."
        install_jenkins_plugins
        exit 0
        ;;
    * ) echo "Usage: deploy_jenkins.sh [-c] [-p]
        [-c] skips installation and applies configuration to an existing installation.
        [-p] installs Jenkins plugins only"
        exit 1
        ;;
  esac
done

echo "Performing full install..."
deploy_aks
deploy_jenkins_ingress
deploy_jenkins
configure_jenkins
install_jenkins_plugins
print_info
