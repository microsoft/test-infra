SP_CLIENT_ID=env.SP_CLIENT_ID?env.SP_CLIENT_ID:""
SP_PASSWORD=env.SP_PASSWORD?env.SP_PASSWORD:""
SP_TENANT=env.SP_TENANT?env.SP_TENANT:""
SUBSCRIPTION_IMAGE_STRING=env.SUBSCRIPTION_IMAGE_STRING?env.SUBSCRIPTION_IMAGE_STRING:""
LOCATION="uksouth"

LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"Ubuntu_1804_LTS_Gen2"
VM_RESOURCE_GROUP="${LINUX_VERSION}-imageBuilder"
VM_NAME="temporary"
ADMIN_USERNAME="jenkins"
VANIllA_IMAGE="${SUBSCRIPTION_IMAGE_STRING}/${LINUX_VERSION}"

pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES') 
    }
    agent { label "ACC-Ubuntu-1804" }

    stages {

        stage('Checkout'){
            steps{
                cleanWs()
                checkout scm
            }
        }

        stage('Install prereqs'){
            steps{
                script{
                    sh  """
                        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                        """
                }
            }
        }

        stage('AZ login'){
            steps{
                script{
                    sh  """
                        az login --service-principal --username ${SP_CLIENT_ID} --tenant ${SP_TENANT} --password ${SP_PASSWORD}
                        """
                }
            }
        }

        stage('Ensure Resource Group Does Not Exist'){
            steps{
                script{
                    sh  """
                        az group delete --name ${VM_RESOURCE_GROUP} --yes || true
                        """
                }
            }
        }

        stage('Create resource group'){
            steps{
                script{
                    sh  """
                        az group create \
                            --name ${VM_RESOURCE_GROUP} \
                            --location ${LOCATION} \
                            --tags 'team=oesdk' 'environment=staging' 'maintainer=oesdkteam' 'deleteMe=true'
                        """
                }
            }
        }

        stage('Launch base VM'){
            steps{
                script{
                    sh  """
                        az vm create \
                            --resource-group ${VM_RESOURCE_GROUP} \
                            --name ${VM_NAME} \
                            --image ${VANIllA_IMAGE} \
                            --admin-username ${ADMIN_USERNAME} \
                            --authentication-type ssh \
                            --size Standard_DC4s_v2 \
                            --generate-ssh-keys
                        """
                }
            }
        }

        stage('Configure base VM'){
            steps{
                script{
                    sh  """
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

                        """
                }
            }
        }
    }

    post ('Clean Up'){
        always{
            cleanWs()
        }
    }
}