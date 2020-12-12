// Pull Request Information
PULL_NUMBER=env.PULL_NUMBER?env.PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"1804"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
COMPILER=env.COMPILER?env.COMPILER:"clang-7"
String[] BUILD_TYPES=['Debug', 'RelWithDebInfo', 'Release']

// Some override for build configuration
LVI_MITIGATION=env.LVI_MITIGATION?env.LVI_MITIGATION:"ControlFlow"
LVI_MITIGATION_SKIP_TESTS=env.LVI_MITIGATION_SKIP_TESTS?env.LVI_MITIGATION_SKIP_TESTS:"OFF"
USE_SNMALLOC=env.USE_SNMALLOC?env.USE_SNMALLOC:"ON"
// TODO Implement simulatioN mode just default for now
OE_SIMULATION=env.OE_SIMULATION?1:0
// Do not package on simulation
PACKAGE=env.OE_SIMULATION?"ON":"OFF"

EXTRA_CMAKE_ARGS=env.EXTRA_CMAKE_ARGS?env.EXTRA_CMAKE_ARGS:"-DLVI_MITIGATION=${LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${LVI_MITIGATION_SKIP_TESTS} -DUSE_SNMALLOC=${USE_SNMALLOC}"

// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"

pipeline {
    options {
        timeout(time: 120, unit: 'MINUTES') 
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
                                runner.cmakeBuildopenenclave("${BUILD_TYPE}","${COMPILER}","${EXTRA_CMAKE_ARGS}")
                                when {
                                    expression { PACKAGE == "ON" }
                                    runner.openenclavepackageInstall("${BUILD_TYPE}","${COMPILER}","${EXTRA_CMAKE_ARGS}")
                                }

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
