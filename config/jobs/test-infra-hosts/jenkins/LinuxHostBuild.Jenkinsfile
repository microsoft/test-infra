SP_CLIENT_ID=env.SP_CLIENT_ID?env.SP_CLIENT_ID:""
SP_PASSWORD=env.SP_PASSWORD?env.SP_PASSWORD:""
SP_TENANT=env.SP_TENANT?env.SP_TENANT:""
SUBSCRIPTION_IMAGE_STRING=env.SP_PASSWORD?env.SP_PASSWORD:""
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

        stage('Create resource group'){
            steps{
                script{
                    sh  """
                        az group create \
                            --name ${VM_RESOURCE_GROUP} \
                            --location ${LOCATION} \
                            --tags 'team=oesdk' 'environment=staging' 'maintainer=oesdkteam'
                        """
                }
            }
        }

        stage('Launch base VM'){
            steps{
                script{
                    sh  """
                        echo 'gotta start somewhere'
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