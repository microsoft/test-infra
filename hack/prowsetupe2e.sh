export LOCATION="uksouth"
export RESOURCE_GROUP="OpenEnclaveCICDDev"
export AKS_CLUSTER_NAME="oe-prow"
export NODE_SIZE="Standard_DC8_v2"
export MIN_NODE_COUNT="3"
export MAX_NODE_COUNT="10"
export PATH_KEY="~/.ssh/id_rsa.pub"

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

# Create Ingress Rules
kubectl create namespace ingress-basic
 
helm repo add stable https://kubernetes-charts.storage.googleapis.com

helm install nginx-ingress stable/nginx-ingress \
    --namespace ingress-basic \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set rbac.create=true

# Create Cluster Bindings
kubectl create clusterrolebinding cluster-admin-binding-"${USER}" \
  --clusterrole=cluster-admin --user="${USER}"

kubectl create namespace test-pods

openssl rand -hex 20 > $PWD/hmac

kubectl create secret generic hmac-token --from-file=$PWD/hmac
kubectl create secret generic oauth-token --from-file=$PWD/oauth
kubectl create secret generic cookie --from-file=secret=cookie.txt
kubectl create secret generic github-oauth-config --from-file=secret=$PWD/secret

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
kubectl apply -f config/prow/cluster/ing_ingress.yaml
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
--from-file=test-infra-periodics.yaml=$PWD/config/jobs/test-infra-periodics.yaml \
--from-file=test-infra-postsubmits.yaml=$PWD/config/jobs/test-infra-postsubmits.yaml \
--from-file=test-infra-presubmits.yaml=$PWD/config/jobs/test-infra-presubmits.yaml \
--from-file=oeedger8r-cpp-presubmits.yaml=$PWD/config/jobs/oeedger8r-cpp/oeedger8r-cpp-presubmits.yaml \
--from-file=oeedger8r-cpp-periodics.yaml=$PWD/config/jobs/oeedger8r-cpp/oeedger8r-cpp-periodics.yaml \
--from-file=openenclave-periodics.yaml=$PWD/config/jobs/openenclave-sdk/openenclave-periodics.yaml \
--from-file=openenclave-presubmits.yaml=$PWD/config/jobs/openenclave-sdk/openenclave-presubmits.yaml \
--dry-run=client -o yaml | kubectl replace configmap job-config -f -

sleep 1m

kubectl get service -l app=nginx-ingress --namespace ingress-basic
