pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES')
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
                script{
                    sh(
                        script: '''
                        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                        sudo apt-get install jq -y
                        '''
                    )  
                }
            }
        }
        stage('AZ login') {
            steps{
                withCredentials([
                    string(credentialsId: 'BUILD-SP-CLIENTID', variable: 'SP_CLIENT_ID'),
                    string(credentialsId: 'BUILD-SP-PASSWORD', variable: 'SP_PASSWORD'),
                    string(credentialsId: 'BUILD-SP-TENANT', variable: 'SP_TENANT')
                ]) {
                    script{
                        sh(
                            script: '''
                            az login --service-principal --username ${SP_CLIENT_ID} --tenant ${SP_TENANT} --password ${SP_PASSWORD} > /dev/null
                            '''
                        )
                    }
                }
            }
        }
        stage('Ensure Resource Group Does Not Exist') {
            steps{
                script{
                    sh(
                        script: '''
                        az group delete --name ${VM_RESOURCE_GROUP} --yes || true
                        '''
                    )  
                }
            }
        }
        stage('Create resource group') {
            steps{
                script{
                    withCredentials([string(credentialsId: 'SUBSCRIPTION-ID', variable: 'SUB_ID')]) {
                        sh(
                            script: """
                            az group create \
                                --name ${VM_RESOURCE_GROUP} \
                                --location ${params.LOCATION} \
                                --tags 'team=oesdk' 'environment=staging' 'maintainer=oesdkteam' 'deleteMe=true'
                            """
                        )
                    }
                }
            }
        }
        stage('Launch base VM') {
            steps{
                script{
                    withCredentials([
                        string(credentialsId: 'VANILLA-IMAGES-SUBSCRIPTION-STRING', variable: 'SUBSCRIPTION_IMAGE_STRING'),
                        string(credentialsId: 'SUBSCRIPTION-ID', variable: 'SUB_ID')
                    ]) {
                        sh(
                            script: '''
                            az vm create \
                                --resource-group ${VM_RESOURCE_GROUP} \
                                --name ${VM_NAME} \
                                --image ${SUBSCRIPTION_IMAGE_STRING}/${LINUX_VERSION} \
                                --admin-username ${ADMIN_USERNAME} \
                                --authentication-type ssh \
                                --size Standard_DC4s_v2 \
                                --generate-ssh-keys
                            '''
                        )
                    }
                }
            }
        }
        stage('Configure base VM') {
            steps{
                script{
                    sh(
                        script: '''
                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME} \
                            --command-id RunShellScript \
                            --scripts "sudo mkdir /home/jenkins/ && sudo chmod 777 /home/jenkins/"

                        sleep 15s

                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME} \
                            --command-id RunShellScript \
                            --scripts "cd /home/jenkins/ && \
                            git clone https://github.com/openenclave/test-infra && \
                            cd test-infra && git checkout master"

                        sleep 2m

                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME} \
                            --command-id RunShellScript \
                            --scripts 'bash /home/jenkins/test-infra/scripts/ansible/install-ansible.sh'

                        sleep 15s

                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME} \
                            --command-id RunShellScript \
                            --scripts 'ansible-playbook /home/jenkins/test-infra/scripts/ansible/oe-contributors-acc-setup.yml'

                        sleep 15s
                        '''
                    )  
                }
            }
        }

        stage('Save VM State') {
            steps{
                script{
                    sh(
                        script: '''
                        az vm deallocate \
                            --resource-group ${VM_RESOURCE_GROUP} \
                            --name ${VM_NAME}

                        az vm generalize \
                            --resource-group ${VM_RESOURCE_GROUP} \
                            --name ${VM_NAME}
                        
                        img_id=\$(az image create \
                            --resource-group ${VM_RESOURCE_GROUP} \
                            --name myImage \
                            --source ${VM_NAME} \
                            --hyper-v-generation V2 | jq -r '.id')

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

                        GALLERY_IMAGE_VERSION="$YY.$MM.$DD${BUILD_ID}"

                        az sig image-version delete \
                            --resource-group "ACC-Images" \
                            --gallery-name ${GALLERY_NAME} \
                            --gallery-image-definition ACC-${LINUX_VERSION} \
                            --gallery-image-version ${GALLERY_IMAGE_VERSION}

                        az sig image-version create \
                            --resource-group "ACC-Images" \
                            --gallery-name ${GALLERY_NAME} \
                            --gallery-image-definition ACC-${LINUX_VERSION} \
                            --gallery-image-version "${GALLERY_IMAGE_VERSION}" \
                            --target-regions "uksouth" "eastus2" "eastus" "westus2" "westeurope" \
                            --replica-count 1 \
                            --managed-image $img_id \
                            --end-of-life-date "$(($YY+1))-$MM-$DD"
                        '''
                    )  
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
                        sh(
                            script: '''
                            az vm create \
                                --resource-group ${VM_RESOURCE_GROUP} \
                                --name ${VM_NAME}-staging \
                                --image "/subscriptions/${SUB_ID}/resourceGroups/${VM_RESOURCE_GROUP}/providers/Microsoft.Compute/images/myImage" \
                                --admin-username ${ADMIN_USERNAME} \
                                --authentication-type ssh \
                                --size Standard_DC4s_v2 \
                                --generate-ssh-keys
                            '''
                        )
                    }
                }
            }
        }

        stage('Test Oeedgr8r') {
            steps{
                script{
                    sh(
                        script: '''
                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME}-staging \
                            --command-id RunShellScript \
                            --scripts 'git clone --recursive https://github.com/openenclave/oeedger8r-cpp.git'

                        sleep 15s

                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME}-staging  \
                            --command-id RunShellScript \
                            --scripts   'cd oeedger8r-cpp && \
                                        mkdir build && \
                                        cmake .. && 
                                        make && \
                                        ctest'
                        '''
                    )  
                }
            }
        }

        stage('Test Open Enclave') {
            steps{
                script{
                    sh(
                        script: '''
                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME}-staging \
                            --command-id RunShellScript \
                            --scripts 'git clone --recursive https://github.com/openenclave/openenclave.git'

                        sleep 15s

                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME}-staging  \
                            --command-id RunShellScript \
                            --scripts   'cd openenclave && \
                                        mkdir build && \
                                        cmake -G "Ninja" .. \
                                        -DLVI_MITIGATION=ControlFlow \
                                        -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin
                                        ninja'
                        '''
                    )  
                }
            }
        }
    }

    post ('Clean Up') {
        always{
            script{
                sh(
                    script: '''
                    az group delete --name ${VM_RESOURCE_GROUP} --yes || true
                    '''
                )
            }
        }
    }
}
