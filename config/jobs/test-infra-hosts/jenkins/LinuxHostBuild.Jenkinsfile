def azVmExecute(String vmName, String command ='echo test') {
    String script = "az vm run-command invoke \
                        --resource-group ${VM_RESOURCE_GROUP}  \
                        --name ${vmName} \
                        --command-id RunShellScript \
                        --scripts ${command}"
    executeWithRetry(script);
}

def executeWithRetry(String script ='echo test') {

    int retry_count = 1;
    int max_retries = 5;

    while(retry_count <= max_retries) {
        try {
            sh  """#!/usr/bin/env bash
                set -o errexit
                set -o pipefail
                source /etc/profile
                ${script}
                """
            break;
        } catch (Exception e) {
            if (retry_count == max_retries) {
                throw e
            }
            sleep(30)
            retry_count += 1
            continue;
        }
    }
}
pipeline {
    options {
        timeout(time: 120, unit: 'MINUTES')
    }
    agent {
        label "ACC-Ubuntu-1804"
    }
    parameters {
        string(name: 'LOCATION', defaultValue: 'uksouth', description: 'Azure Region')
        string(name: 'SGX', defaultValue: 'SGX', description: 'SGX enabled')
        string(name: 'LINUX_VERSION', defaultValue: 'Ubuntu_1804_LTS_Gen2', description: 'Linux version to build')
    }
    environment {
        BUILD_ID = "${currentBuild.number}"
        VM_RESOURCE_GROUP = "${params.LINUX_VERSION}-imageBuilder-${currentBuild.number}"
        VM_NAME = "temporary"
        ADMIN_USERNAME = "jenkins"
        GALLERY_DEFN = "${params.SGX}-${params.LINUX_VERSION}"
        PUBLISHER = "${params.SGX}-${params.LINUX_VERSION}"
        OFFER = "${params.SGX}-${params.LINUX_VERSION}"
        SKU = "${params.SGX}-${params.LINUX_VERSION}"
        GALLERY_NAME = "ACC_Images"
    }
    stages {
        stage('Checkout') {
            steps{
                cleanWs()
            }
        }
        stage('Install prereqs') {
            steps{
                executeWithRetry('curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash');
                executeWithRetry('sudo apt-get install jq -y');
            }
        }
        stage('AZ login') {
            steps{
                withCredentials([
                    string(credentialsId: 'BUILD-SP-CLIENTID', variable: 'SP_CLIENT_ID'),
                    string(credentialsId: 'BUILD-SP-PASSWORD', variable: 'SP_PASSWORD'),
                    string(credentialsId: 'BUILD-SP-TENANT', variable: 'SP_TENANT')
                ]) {
                    executeWithRetry("az login --service-principal --username ${SP_CLIENT_ID} --tenant ${SP_TENANT} --password ${SP_PASSWORD} > /dev/null");
                }
            }
        }
        stage('Ensure Resource Group Does Not Exist') {
            steps{
                executeWithRetry("az group delete --name ${VM_RESOURCE_GROUP} --yes || true");
            }
        }


        stage('Create resource group') {
            steps{
                withCredentials([string(credentialsId: 'SUBSCRIPTION-ID', variable: 'SUB_ID')]) {
                    executeWithRetry("az group create \
                                        --name ${VM_RESOURCE_GROUP} \
                                        --location ${params.LOCATION} \
                                        --tags 'team=oesdk' 'environment=staging' 'maintainer=oesdkteam' 'deleteMe=true'");
                }
            }
        }

        stage('Launch base VM') {
            steps{
                withCredentials([
                    string(credentialsId: 'VANILLA-IMAGES-SUBSCRIPTION-STRING', variable: 'SUBSCRIPTION_IMAGE_STRING'),
                    string(credentialsId: 'SUBSCRIPTION-ID', variable: 'SUB_ID')]) {

                    executeWithRetry("az vm create \
                                        --resource-group ${VM_RESOURCE_GROUP} \
                                        --name ${VM_NAME} \
                                        --image ${SUBSCRIPTION_IMAGE_STRING}/${LINUX_VERSION} \
                                        --admin-username ${ADMIN_USERNAME} \
                                        --authentication-type ssh \
                                        --size Standard_DC4s_v2 \
                                        --generate-ssh-keys");
                }
            }
        }

        stage('Configure base VM') {
            steps{
                azVmExecute("${VM_NAME}", "'sudo mkdir /home/jenkins/'")
                azVmExecute("${VM_NAME}", "'sudo chmod 777 /home/jenkins/'")
                azVmExecute("${VM_NAME}", "'git clone --recursive https://github.com/openenclave/openenclave /home/jenkins/openenclave'") // this needs to take a configurable org
                azVmExecute("${VM_NAME}", "'cd /home/jenkins/openenclave  && git checkout master'") // this needs to actually check out a merge ref
                azVmExecute("${VM_NAME}", "'bash /home/jenkins/openenclave/scripts/ansible/install-ansible.sh'")
                azVmExecute("${VM_NAME}", "'ansible-playbook /home/jenkins/openenclave/scripts/ansible/oe-contributors-acc-setup.yml'")
                azVmExecute("${VM_NAME}", "'sudo rm -rf /home/jenkins/openenclave'")
            }
        }

        stage('Create local Docker Image') {
            steps{
                azVmExecute("${VM_NAME}", "'sudo docker build --no-cache=true --build-arg ubuntu_version=18.04 --build-arg devkits_uri=https://tcpsbuild.blob.core.windows.net/tcsp-build/OE-CI-devkits-dd4c992d.tar.gz -t oetools-full-18.04:e2elite -f /home/jenkins/openenclave.jenkins/infrastructure/dockerfiles/linux/Dockerfile.full .'")
            }
        }

        stage('Save VM State') {
            steps{
                script{
                    withCredentials([
                        string(credentialsId: 'VANILLA-IMAGES-SUBSCRIPTION-STRING', variable: 'SUBSCRIPTION_IMAGE_STRING'),
                        string(credentialsId: 'SUBSCRIPTION-ID', variable: 'SUB_ID')
                    ]) {

                        executeWithRetry("az vm deallocate \
                                                --resource-group ${VM_RESOURCE_GROUP} \
                                                --name ${VM_NAME}")

                        executeWithRetry("az vm generalize \
                                                --resource-group ${VM_RESOURCE_GROUP} \
                                                --name ${VM_NAME}")

                        executeWithRetry("img_id=\$(az image create \
                                                --resource-group ${VM_RESOURCE_GROUP} \
                                                --name myImage \
                                                --source ${VM_NAME} \
                                                --hyper-v-generation V2 | jq -r '.id'

                                            az sig image-definition create \
                                                --resource-group ACC-Images \
                                                --gallery-name ${GALLERY_NAME} \
                                                --gallery-image-definition ${GALLERY_DEFN} \
                                                --publisher ${PUBLISHER} \
                                                --offer ${OFFER} \
                                                --sku ${SKU} \
                                                --os-type Linux \
                                                --os-state generalized \
                                                --hyper-v-generation V2 || true

                                            YY=$(date +%Y)
                                            DD=$(date +%d)
                                            MM=$(date +%m)

                                            GALLERY_IMAGE_VERSION=\"$YY.$MM.$DD${BUILD_ID}\"

                                            az sig image-version delete \
                                                --resource-group ACC-Images \
                                                --gallery-name ${GALLERY_NAME} \
                                                --gallery-image-definition ACC-${LINUX_VERSION} \
                                                --gallery-image-version ${GALLERY_IMAGE_VERSION}

                                            az sig image-version create \
                                                --resource-group ACC-Images \
                                                --gallery-name ${GALLERY_NAME} \
                                                --gallery-image-definition ACC-${LINUX_VERSION} \
                                                --gallery-image-version "${GALLERY_IMAGE_VERSION}" \
                                                --target-regions \"uksouth\" \"eastus2\" \"eastus\" \"westus2\" \"westeurope\" \
                                                --replica-count 1 \
                                                --managed-image $img_id \
                                                --end-of-life-date \"$(($YY+1))-$MM-$DD\" \
                                                --no-wait")
                    } 
                }
            }
        }

        stage('Launch a VM After Saving State') {
            steps{
                script{
                    withCredentials([
                        string(credentialsId: 'VANILLA-IMAGES-SUBSCRIPTION-STRING', variable: 'SUBSCRIPTION_IMAGE_STRING'),
                        string(credentialsId: 'SUBSCRIPTION-ID', variable: 'SUB_ID')
                    ]) {
                        executeWithRetry("az vm create \
                                            --resource-group ${VM_RESOURCE_GROUP} \
                                            --name ${VM_NAME}-staging \
                                            --image \"/subscriptions/${SUB_ID}/resourceGroups/${VM_RESOURCE_GROUP}/providers/Microsoft.Compute/images/myImage\" \
                                            --admin-username ${ADMIN_USERNAME} \
                                            --authentication-type ssh \
                                            --size Standard_DC4s_v2 \
                                            --generate-ssh-keys")
                    }
                }
            }
        }

        stage('Test Oeedgr8r') {
            steps{
                script{
                    azVmExecute("${VM_NAME}-staging", "'git clone --recursive https://github.com/openenclave/oeedger8r-cpp.git /home/jenkins/oeedger8r-cpp/'")
                    azVmExecute("${VM_NAME}-staging", "'mkdir /home/jenkins/oeedger8r-cpp/build; cd /home/jenkins/oeedger8r-cpp/build && cmake .. -G Ninja && ninja && ctest'")
                }
            }
        }

        stage('Test Open Enclave') {
            steps{
                script{
                    azVmExecute("${VM_NAME}-staging", "'git clone --recursive https://github.com/openenclave/openenclave.git /home/jenkins/openenclave'")
                    azVmExecute("${VM_NAME}-staging", "'mkdir /home/jenkins/openenclave/build'")
                    azVmExecute("${VM_NAME}-staging", "'cd /home/jenkins/openenclave/build && \
                                                        cmake -G Ninja .. \
                                                        -DLVI_MITIGATION=ControlFlow \
                                                        -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin && \
                                                        ninja && \
                                                        ctest'")
                }
            }
        }
    }

    post ('Clean Up') {
        always{
            executeWithRetry("az group delete --name ${VM_RESOURCE_GROUP} --yes || true")
        }
    }
}
