pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES')
    }

    parameters {
        string(name: 'LINUX_VERSION', defaultValue: params.LINUX_VERSION ?:'Ubuntu-1804', description: 'Linux version to build')
        string(name: 'COMPILER', defaultValue: params.COMPILER ?:'clang-7', description: 'Compiler version')
        string(name: 'DOCKER_TAG', defaultValue: params.DOCKER_TAG ?:'latest', description: 'Docker image version')
        string(name: 'PULL_NUMBER', defaultValue: params.PULL_NUMBER ?:'master',  description: 'Branch/PR to build')
    }

    environment {
        // Shared library config, check out common.groovy!
        SHARED_LIBRARY="/config/jobs/openenclave-mbedtls/jenkins/common.groovy"
    }

    agent {
        label "ACC-${LINUX_VERSION}"
    }
    stages {
        stage('Checkout') {
            steps{
                cleanWs()
                checkout scm
            }
        }
        stage('Build and Test') {
            steps{
                script{
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    String[] BUILD_TYPES=['Debug', 'RelWithDebInfo', 'Release']
                    for(BUILD_TYPE in BUILD_TYPES){
                        stage("Ubuntu ${params.LINUX_VERSION} Build - ${BUILD_TYPE}"){
                            try{
                                runner.cleanup()
                                runner.checkout("${params.PULL_NUMBER}")
                                runner.cmakeBuildOpenEnclaveMbedTLS("${BUILD_TYPE}","${params.COMPILER}")
                            } catch (Exception e) {
                                // Do something with the exception 
                                error "Program failed, please read logs..."
                            } finally {
                                runner.cleanup()
                            }
                        }
                    } 
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
