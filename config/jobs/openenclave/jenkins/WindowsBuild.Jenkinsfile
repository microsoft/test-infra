// Pull Request Information
PULL_NUMBER=env.PULL_NUMBER?env.PULL_NUMBER:"master"

// OS Version Configuration
WINDOWS_VERSION=env.WINDOWS_VERSION?env.WINDOWS_VERSION:"Windows-2019"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
COMPILER=env.COMPILER?env.COMPILER:"MSVC"
BUILD_TYPE=env.BUILD_TYPE?env.BUILD_TYPE:"Debug"

// Some override for build configuration
LVI_MITIGATION=env.LVI_MITIGATION?env.LVI_MITIGATION:"ControlFlow"
LVI_MITIGATION_SKIP_TESTS=env.LVI_MITIGATION_SKIP_TESTS?env.LVI_MITIGATION_SKIP_TESTS:"OFF"
USE_SNMALLOC=env.USE_SNMALLOC?env.USE_SNMALLOC:"ON"

EXTRA_CMAKE_ARGS=env.EXTRA_CMAKE_ARGS?env.EXTRA_CMAKE_ARGS:"-DLVI_MITIGATION=${LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${LVI_MITIGATION_SKIP_TESTS} -DUSE_SNMALLOC=${USE_SNMALLOC}"

// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"

// whether to run as an e2e test
E2E=env.E2E?env.E2E:"OFF"

pipeline {
    options {
        timeout(time: 180, unit: 'MINUTES') 
    }
    agent { label "ACC-${WINDOWS_VERSION}" }

    stages {
        stage('Checkout'){
            steps{
                cleanWs()
                checkout scm
            }
        }

        // Temporarily run always as e2e
        stage('Install Prereqs (Optional)'){
            steps{
                script{
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    if("${E2E}" == "ON"){
                        stage("${WINDOWS_VERSION} Setup"){
                            try{
                                runner.cleanup()
                                runner.checkout("${PULL_NUMBER}")
                                runner.installOpenEnclavePrereqs()
                            } catch (Exception e) {
                                // Do something with the exception 
                                error "Program failed, please read logs..."
                            }
                        }
                    }
                }
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
                                runner.cmakeBuildopenenclave("${BUILD_TYPE}","${COMPILER}","${EXTRA_CMAKE_ARGS}")
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