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
        string(name: 'LINUX_VERSION', defaultValue: 'Ubuntu_1804_LTS_Gen2', description: 'Linux version to build ')
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build ')
    }
    environment {
        VM_RESOURCE_GROUP = "${params.LINUX_VERSION}-imageBuilder-${currentBuild.number}"
        VM_NAME = "temporary"
        ADMIN_USERNAME = "jenkins"
        GALLERY_DEFN = "${params.SGX}-${params.LINUX_VERSION}"
        PUBLISHER = "${params.SGX}-${params.LINUX_VERSION}"
        OFFER = "${params.SGX}-${params.LINUX_VERSION}"
        SKU = "${params.SGX}-${params.LINUX_VERSION}"
    }
    stages {
        stage('Checkout') {
            steps{
                cleanWs()
                //checkout scm
            }
        }
        stage('Install prereqs') {
            steps{
                script{
                    sh(
                        script: """
                        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                        sudo apt-get install jq -y
                        """
                    )  
                }
            }
        }
        stage('AZ login') {
            steps{
                withCredentials([
                string(credentialsId: 'BUILD-SP-CLIENTID', variable: 'SP_CLIENT_ID'), 
                string(credentialsId: 'BUILD-SP-PASSWORD', variable: 'SP_PASSWORD'), 
                string(credentialsId: 'BUILD-SP-TENANT', variable: 'SP_TENANT')]) {
                    script{
                        sh(
                            script: """
                            az login --service-principal --username ${SP_CLIENT_ID} --tenant ${SP_TENANT} --password ${SP_PASSWORD}
                            """
                        )
                    }
                }
            }
        }
        stage('Ensure Resource Group Does Not Exist') {
            steps{
                script{
                    sh(
                        script: """
                        az group delete --name ${VM_RESOURCE_GROUP} --yes || true
                        """
                    )  
                }
            }
        }
        stage('Create resource group') {
            steps{
                script{
                    sh(
                        script: """
                        az group create \
                            --name ${VM_RESOURCE_GROUP} \
                            --location ${LOCATION} \
                            --tags 'team=oesdk' 'environment=staging' 'maintainer=oesdkteam' 'deleteMe=true'
                        """
                    )  
                }
            }
        }
        stage('Launch base VM') {
            steps{
                script{
                    withCredentials([string(credentialsId: 'VANILLA-IMAGES-SUBSCRIPTION-STRING', variable: 'SUBSCRIPTION_IMAGE_STRING')]) {
                        sh(
                            script: """
                            az vm create \
                                --resource-group ${VM_RESOURCE_GROUP} \
                                --name ${VM_NAME} \
                                --image "${SUBSCRIPTION_IMAGE_STRING}/${LINUX_VERSION}" \
                                --admin-username ${ADMIN_USERNAME} \
                                --authentication-type ssh \
                                --size Standard_DC4s_v2 \
                                --generate-ssh-keys
                            """
                        )
                    }
                }
            }
        }
        stage('Configure base VM') {
            steps{
                script{
                    sh(
                        script: """
                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME} \
                            --command-id RunShellScript \
                            --scripts pwd && ls -l

                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME} \
                            --command-id RunShellScript \
                            --scripts mkdir /home/jenkins/

                        sleep 1m

                        az vm run-command invoke \
                            --resource-group ${VM_RESOURCE_GROUP}  \
                            --name ${VM_NAME} \
                            --command-id RunShellScript \
                            --scripts 'cd /home/jenkins/ && \
                            git clone https://github.com/openenclave/test-infra && \
                            cd test-infra && git checkout ${env.BRANCH}

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

                        """
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
                            --gallery-name ACC_Images \
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

                        RAND=$((1 + $RANDOM % 1000))
                        GALLERY_IMAGE_VERSION="$YY.$MM.$DD$RAND"
                        GALLERY_NAME="ACC_Images"

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
        stage('Test VM State') {
            steps{
                script{
                    sh(
                        script: '''
                        echo "We should test..."
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
