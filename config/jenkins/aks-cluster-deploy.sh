#! /usr/bin/env bash
#
# Creates a new AKS cluster to host the Jenkins service.
#
# Instructions:
#   1. Set a new resource group in the section below
#   2. Modify the remaining variables with your own in the section below 
#
# -----------BEGIN-CONFIGURATION-----------
set -e

## General Azure Configuration
# WARNING: use a *new* resource group! This script WILL delete existing resources in your resource group.
readonly RESOURCE_GROUP=""
# Azure region code. To list all region codes use: `az account list-locations -o table`
readonly LOCATION="eastus"

## AKS Configurations
readonly AKS_CLUSTER_NAME=""
readonly AKS_PUBLIC_IP_NAME=""
# For other node sizes see:
# https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
readonly NODE_SIZE="Standard_D8_v3"
readonly MIN_NODE_COUNT="1"
readonly MAX_NODE_COUNT="10"
# (Optional) Provide an SSH key if you want to SSH into your AKS cluster nodes
readonly PATH_KEY="~/.ssh/id_rsa.pub"

## Jenkins Master configuration
# This controls the URL that would be used to access the Jenkins master
# E.g. https://prow-jenkins-test.eastus.cloudapp.azure.com/
readonly DNS_LABEL="prow-jenkins-test"

# ------------END-CONFIGURATION------------

# Delete resource group if exists
if [[ $(az group show --name ${RESOURCE_GROUP}) ]]; then
  az group delete --name ${RESOURCE_GROUP} --yes
fi

# Create resource group
az group create --location ${LOCATION} --name ${RESOURCE_GROUP}

# Create AKS Cluster
# This will also create a new and independent Service Principal from the one used by Jenkins itself
az aks create \
  --resource-group ${RESOURCE_GROUP} \
  --name ${AKS_CLUSTER_NAME} \
  --node-vm-size ${NODE_SIZE} \
  --vm-set-type VirtualMachineScaleSets \
  --load-balancer-sku standard \
  --location ${LOCATION} \
  --enable-cluster-autoscaler \
  --min-count ${MIN_NODE_COUNT} \
  --max-count ${MAX_NODE_COUNT} \
  --ssh-key-value ${PATH_KEY} \
  --kubernetes-version 1.18.8

# Get AKS Credentials
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --overwrite-existing

# Create a namespace for your ingress resource
kubectl create namespace ingress

# Add the official stable and ingress-nginx repos
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update

# Get AKS Resource Group Name
readonly AKS_RESOURCE_GROUP=$(az aks show --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --query nodeResourceGroup -o tsv)

# Assign Static IP
readonly STATIC_IP=$(az network public-ip create --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_PUBLIC_IP_NAME} --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv --dns-name ${DNS_LABEL})

# Determine FQDN
readonly JENKINS_FQDN=$(az network public-ip list --resource-group ${AKS_RESOURCE_GROUP} --query "[?name=='${AKS_PUBLIC_IP_NAME}'].[dnsSettings.fqdn]" -o tsv)

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

# Create cluster bindings
kubectl create clusterrolebinding cluster-admin-binding-"${USER}" --clusterrole=cluster-admin --user="${USER}"

# Deploy Kubernetes services/pods
# A small delay is necessary so ingress setup doesn't fail due to missing dependencies from jenkins-master-deployment
kubectl apply -f kubernetes/jenkins-cluster-role.yml
kubectl apply -f kubernetes/jenkins-master-deployment.yml 
sleep 60
kubectl apply -f kubernetes/jenkins-ingress.yml

# Output details
echo "Created https://${JENKINS_FQDN}"
echo "AKS Resource Group: ${AKS_RESOURCE_GROUP}"
echo "Public IP: ${STATIC_IP}"
