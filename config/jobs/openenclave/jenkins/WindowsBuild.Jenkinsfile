// Pull Request Information
PULL_NUMBER=env.PULL_NUMBER?env.PULL_NUMBER:"master"

// OS Version Configuration
WINDOWS_VERSION=env.WINDOWS_VERSION?env.WINDOWS_VERSION:"2019"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
COMPILER=env.COMPILER?env.COMPILER:"MSVC"
BUILD_TYPE=env.BUILD_TYPE?env.BUILD_TYPE:"Debug"
// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"

pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES') 
    }
    agent { label "SGXFLC-Windows-${WINDOWS_VERSION}-Docker" }

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
                    stage("Windows ${WINDOWS_VERSION} Build - ${BUILD_TYPE}"){
                        script {
                            try{
                                runner.cleanup()
                                runner.checkout("${PULL_NUMBER}")
                                runner.cmakeBuildopenenclave("${BUILD_TYPE}","${COMPILER}")
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
