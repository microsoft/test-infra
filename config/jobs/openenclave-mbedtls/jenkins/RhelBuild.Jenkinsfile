// Pull Request Information
PULL_NUMBER=env.PULL_NUMBER?env.PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"RHEL-8"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
COMPILER=env.COMPILER?env.COMPILER:"gcc"
String[] BUILD_TYPES=['Debug', 'RelWithDebInfo', 'Release']

// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/openenclave-mbedtls/jenkins/common.groovy"

pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES') 
    }
    agent { label "ACC-${LINUX_VERSION}" }

    stages {
        stage('Checkout'){
            steps{
                cleanWs()
                checkout scm
            }
        }
        stage('Build'){
            steps{
                script{
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    for(BUILD_TYPE in BUILD_TYPES){
                        stage("Ubuntu ${LINUX_VERSION} Build - ${BUILD_TYPE}"){
                            try{
                                runner.cleanup()
                                runner.checkout("${PULL_NUMBER}")
                                runner.cmakeBuildoeedger8r("${BUILD_TYPE}","${COMPILER}")
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
