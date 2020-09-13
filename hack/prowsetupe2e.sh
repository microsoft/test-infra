export LOCATION="uksouth"
export RESOURCE_GROUP="OpenEnclaveCICDDev"
export AKS_CLUSTER_NAME="oe-prow-dev"
export NODE_SIZE="Standard_DC8_v2"
export MIN_NODE_COUNT="3"
export MAX_NODE_COUNT="10"
export PATH_KEY="~/.ssh/id_rsa.pub"
export DNS_LABEL="oe-prow-status-dev"

# Delete Any Existing Resources
az group delete --name ${RESOURCE_GROUP} --yes
az group delete --name MC_${RESOURCE_GROUP}_${AKS_CLUSTER_NAME}_${LOCATION} --yes

# Create Resource Group
az group create --location ${LOCATION} --name ${RESOURCE_GROUP}

# Create AKS Cluster
az aks create --resource-group ${RESOURCE_GROUP} \
    --name ${AKS_CLUSTER_NAME} \
    --node-vm-size ${NODE_SIZE} \
    --max-count ${MAX_NODE_COUNT} \
    --vm-set-type VirtualMachineScaleSets \
    --load-balancer-sku standard \
    --location ${LOCATION} \
    --enable-cluster-autoscaler \
    --service-principal ${SERVICE_PRINCIPAL} \
    --client-secret ${CLIENT_SECRET} \
    --min-count ${MIN_NODE_COUNT} \
    --max-count ${MAX_NODE_COUNT} \
    --ssh-key-value ${PATH_KEY} \
    --kubernetes-version 1.17.7 \
    --aks-custom-headers "usegen2vm=true"

# Get AKS Credentials
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --overwrite-existing

# Create a namespace for your ingress resources
kubectl create namespace ingress-basic

# Add the official stable repo
helm repo add stable https://kubernetes-charts.storage.googleapis.com/

# Get AKS Resource Group Name
AKS_RESOURCE_GROUP=$(az aks show --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --query nodeResourceGroup -o tsv)
echo ${AKS_RESOURCE_GROUP}

# Assign Static IP
STATIC_IP=$(az network public-ip create --resource-group ${AKS_RESOURCE_GROUP} --name myAKSPublicIP --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv --dns-name ${DNS_LABEL})
echo ${STATIC_IP}

#Get FQDN
az network public-ip list --resource-group ${AKS_RESOURCE_GROUP} --query "[?name=='myAKSPublicIP'].[dnsSettings.fqdn]" -o tsv

# Use Helm to deploy an NGINX ingress controller
helm install nginx stable/nginx-ingress \
    --namespace ingress-basic \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.service.loadBalancerIP="${STATIC_IP}" \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set rbac.create=true

# Create Cluster Bindings
kubectl create clusterrolebinding cluster-admin-binding-"${USER}" \
  --clusterrole=cluster-admin --user="${USER}"

# Create test pods namespace
kubectl create namespace test-pods

# Credentials
openssl rand -hex 20 > $PWD/hmac
kubectl create secret generic hmac-token --from-file=$PWD/hmac
kubectl create secret generic oauth-token --from-file=$PWD/oauth
kubectl -n test-pods create secret generic gcs-credentials --from-file=service-account.json

kubectl apply -f config/prow/cluster/configs.yaml
kubectl apply -f config/prow/cluster/hook_deployment.yaml
kubectl apply -f config/prow/cluster/hook_service.yaml
kubectl apply -f config/prow/cluster/plank_deployment.yaml
kubectl apply -f config/prow/cluster/sinker_deployment.yaml
kubectl apply -f config/prow/cluster/deck_deployment.yaml
kubectl apply -f config/prow/cluster/deck_service.yaml
kubectl apply -f config/prow/cluster/horolgium_deployment.yaml
kubectl apply -f config/prow/cluster/tide_deployment.yaml
kubectl apply -f config/prow/cluster/tide_service.yaml
kubectl apply -f config/prow/cluster/ing_ingress_dev.yaml
kubectl apply -f config/prow/cluster/statusreconciler_deployment.yaml
kubectl apply -f config/prow/cluster/test_pods.yaml
kubectl apply -f config/prow/cluster/deck_rbac.yaml
kubectl apply -f config/prow/cluster/horolgium_rbac.yaml
kubectl apply -f config/prow/cluster/plank_rbac.yaml
kubectl apply -f config/prow/cluster/sinker_rbac.yaml
kubectl apply -f config/prow/cluster/hook_rbac.yaml
kubectl apply -f config/prow/cluster/tide_rbac.yaml
kubectl apply -f config/prow/cluster/statusreconciler_rbac.yaml
kubectl apply -f config/prow/cluster/crier_rbac.yaml
kubectl apply -f config/prow/cluster/crier_deployment.yaml

# Apply config and plugins
kubectl create configmap config --from-file=config.yaml=$PWD/config/prow/config.yaml  --dry-run=client -o yaml | kubectl replace configmap config -f -
kubectl create configmap plugins --from-file=$PWD/config/prow/plugins.yaml --dry-run=client -o yaml   | kubectl replace configmap plugins -f -

# Create job config map
kubectl create configmap job-config \
--from-file=test-infra-periodics.yaml=$PWD/config/jobs/test-infra/test-infra-periodics.yaml \
--from-file=test-infra-postsubmits.yaml=$PWD/config/jobs/test-infra/test-infra-postsubmits.yaml \
--from-file=test-infra-pre-submits.yaml=$PWD/config/jobs/test-infra/test-infra-pre-submits.yaml \
--from-file=oeedger8r-cpp-pre-submits.yaml=$PWD/config/jobs/oeedger8r-cpp/oeedger8r-cpp-pre-submits.yaml \
--from-file=oeedger8r-cpp-presubmits.yaml=$PWD/config/jobs/oeedger8r-cpp/oeedger8r-cpp-presubmits.yaml \
--from-file=oeedger8r-cpp-periodics.yaml=$PWD/config/jobs/oeedger8r-cpp/oeedger8r-cpp-periodics.yaml \
--from-file=openenclave-periodics.yaml=$PWD/config/jobs/openenclave/openenclave-periodics.yaml \
--from-file=openenclave-pre-submits.yaml=$PWD/config/jobs/openenclave/openenclave-pre-submits.yaml \
--dry-run=client -o yaml | kubectl replace configmap job-config -f -

# Ending remarks
az network public-ip list --resource-group ${AKS_RESOURCE_GROUP} --query "[?name=='myAKSPublicIP'].[dnsSettings.fqdn]" -o tsv

# Generate TLS cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    -subj "/CN=${DNS_LABEL}.uksouth.cloudapp.azure.com/O=aks-ingress-tls"

# Create TLS secret
kubectl create secret tls prow-tls \
    --namespace ingress-basic \
    --key aks-ingress-tls.key \
    --cert aks-ingress-tls.crt
