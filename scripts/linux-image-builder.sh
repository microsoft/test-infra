#!/bin/bash
set -ex

##====================================================================================
## Linux Image Builder Script
##====================================================================================

if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo " Usage: "
    echo " ./scripts/linux-image-builder.sh"
    echo "        -b Ubuntu_1804_LTS_Gen2|Ubuntu_1604_LTS_Gen2|RHEL_8_Gen2"
    echo "        -s image string"
    echo "        -l location"
    echo ""
    exit 0
fi

# Default linux version to build 
LINUX_VERSION="Ubuntu_1804_LTS_Gen2"

# Default subscription image String
SUBSCRIPTION_IMAGE_STRING=""

# Default Location
LOCATION="uksouth"

# Parse the command line - keep looping as long as there is at least one more argument
while [[ $# -gt 0 ]]; do
    key=$1
    case $key in
        -b)
        shift # past the key and to the value
        LINUX_VERSION=$1
        ;;
        -s)
        shift # past the key and to the value
        SUBSCRIPTION_IMAGE_STRING=$1
        ;;
        -l)
        shift # past the key and to the value
        LOCATION=$1
        ;;
        *)
        echo "Unknown option '${key}'"
        exit 1
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

# Check we are building a supported image
if [[ ${LINUX_VERSION} != "Ubuntu_1804_LTS_Gen2" && ${LINUX_VERSION} != "Ubuntu_1604_LTS_Gen2" && ${LINUX_VERSION} != "RHEL_8_Gen2" ]]; then
   echo "Invalid value for ${LINUX_VERSION}"
   exit 1
fi

# Some defaults
VM_RESOURCE_GROUP="${LINUX_VERSION}-imageBuilder"
VM_NAME=temporary
ADMIN_USERNAME=jenkins
VANIllA_IMAGE="${SUBSCRIPTION_IMAGE_STRING}/${LINUX_VERSION}"

# Delete resource group, if exists. This can be triggered if prior runs failed to clean up.
#if [ "$(az group exists --name ${VM_RESOURCE_GROUP})" == "true" ]; then
#    az group delete --name ${VM_RESOURCE_GROUP} --yes
#fi

az group delete --name ${VM_RESOURCE_GROUP} --yes || true

# Create resource group
az group create \
    --name ${VM_RESOURCE_GROUP} \
    --location ${LOCATION} \
    --tags "team=oesdk" "environment=staging" "maintainer=oesdkteam"

# Create a VM from the base image
az vm create \
   --resource-group ${VM_RESOURCE_GROUP} \
   --name ${VM_NAME} \
   --image ${VANIllA_IMAGE} \
   --admin-username ${ADMIN_USERNAME} \
   --authentication-type ssh \
   --size Standard_DC4s_v2 \
   --ssh-key-values ~/.ssh/id_rsa.pub

# Configure vm
# clone test-infra, install ansible, run ansible to configure host, remove test-infra but leave ansible installed
az vm run-command invoke \
    --resource-group ${VM_RESOURCE_GROUP}  \
    --name ${VM_NAME} \
    --command-id RunShellScript \
    --scripts 'mkdir /home/jenkins/'

sleep 1m

az vm run-command invoke \
    --resource-group ${VM_RESOURCE_GROUP}  \
    --name ${VM_NAME} \
    --command-id RunShellScript \
    --scripts 'cd /home/jenkins/ && git clone https://github.com/openenclave/test-infra'

sleep 1m

az vm run-command invoke \
    --resource-group ${VM_RESOURCE_GROUP}  \
    --name ${VM_NAME} \
    --command-id RunShellScript \
    --scripts 'bash /home/jenkins/test-infra/scripts/ansible/install-ansible.sh'

sleep 1m

az vm run-command invoke \
    --resource-group ${VM_RESOURCE_GROUP}  \
    --name ${VM_NAME} \
    --command-id RunShellScript \
    --scripts 'ansible-playbook /home/jenkins/test-infra/scripts/ansible/oe-contributors-acc-setup.yml'

sleep 1m

# Test Image
az vm run-command invoke \
    --resource-group ${VM_RESOURCE_GROUP}  \
    --name ${VM_NAME} \
    --command-id RunShellScript \
    --scripts 'cd /home/jenkins/test-infra/' # && bash images/test/validate.sh'

sleep 1m

# Destroy everything to prepare for generalizaiton
az vm run-command invoke \
    --resource-group ${VM_RESOURCE_GROUP}  \
    --name ${VM_NAME} \
    --command-id RunShellScript \
    --scripts 'sudo rm -rf /home/jenkins/*'

sleep 1m

# Create VM image by deallocating, generalizing and then making the actual image
az vm deallocate \
    --resource-group ${VM_RESOURCE_GROUP} \
    --name ${VM_NAME}

az vm generalize \
    --resource-group ${VM_RESOURCE_GROUP} \
    --name ${VM_NAME}

img_id="$(az image create \
    --resource-group ${VM_RESOURCE_GROUP} \
    --name myImage --source ${VM_NAME} \
    --hyper-v-generation V2 | jq -r '.id')"

# Create an image definition. If the image definition already exists, the below command will not fail.
az sig image-definition create \
    --resource-group ACC-Images \
    --gallery-name ACC_Images \
    --gallery-image-definition ACC-${LINUX_VERSION} \
    --publisher ACC-Images-Brett-Test \
    --offer ACC-${LINUX_VERSION} \
    --sku ACC-${LINUX_VERSION} \
    --os-type Linux \
    --os-state generalized \
    --hyper-v-generation V2 || true

# Store Date info for End Of Life date and versioning.
YY=$(date +%Y)
DD=$(date +%d)
MM=$(date +%m)

GALLERY_IMAGE_VERSION="$YY.$MM.$DD"
GALLERY_NAME="ACC_Images"

# If the target image version doesn't exist, the below
# command will not fail because it is idempotent.
az sig image-version delete \
    --resource-group "ACC-Images" \
    --gallery-name ${GALLERY_NAME} \
    --gallery-image-definition ACC-${LINUX_VERSION} \
    --gallery-image-version ${GALLERY_IMAGE_VERSION}

# Upload and replciate image.
## TODO, need a better image verisoning sysem.
az sig image-version create \
    --resource-group "ACC-Images" \
    --gallery-name ${GALLERY_NAME} \
    --gallery-image-definition ACC-${LINUX_VERSION} \
    --gallery-image-version "${GALLERY_IMAGE_VERSION}" \
    --target-regions "uksouth" "eastus2" "eastus" "westus2" "westeurope" \
    --replica-count 1 \
    --managed-image $img_id \
    --end-of-life-date "$(($YY+1))-$MM-$DD"

# Clean up
az group delete \
    --name ${VM_RESOURCE_GROUP} \
    --yes

