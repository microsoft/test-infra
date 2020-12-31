// Pull Request Information
PULL_NUMBER=env.PULL_NUMBER?env.PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"RHEL-8"
// Some Defaults for general build info
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
COMPILER=env.COMPILER?env.COMPILER:"gcc"
BUILD_TYPE=env.BUILD_TYPE?env.BUILD_TYPE:"Debug"

// Some override for build configuration
LVI_MITIGATION=env.LVI_MITIGATION?env.LVI_MITIGATION:"None"
LVI_MITIGATION_SKIP_TESTS=env.LVI_MITIGATION_SKIP_TESTS?env.LVI_MITIGATION_SKIP_TESTS:"OFF"
USE_SNMALLOC=env.USE_SNMALLOC?env.USE_SNMALLOC:"ON"

// Openenclave extra build configs 
EXTRA_CMAKE_ARGS=env.EXTRA_CMAKE_ARGS?env.EXTRA_CMAKE_ARGS:"-DLVI_MITIGATION=${LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${LVI_MITIGATION_SKIP_TESTS} -DUSE_SNMALLOC=${USE_SNMALLOC}"

// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"

pipeline {
    options {
        timeout(time: 180, unit: 'MINUTES') 
    }
    agent { label "ACC-${LINUX_VERSION}" }

    stages {
        // Check out test infra repo as need shared libs
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

                    stage("RHEL ${LINUX_VERSION} Setup"){
                        try{
                            runner.cleanup()
                            runner.checkout("${PULL_NUMBER}")
                            //runner.installOpenEnclavePrereqs()
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        }
                    }
                }
            }
        }

        // Go through Build stages
        stage('Build'){
            steps{
                script{
                    def runner = load pwd() + "${SHARED_LIBRARY}"

                    // Build and test in Hardware mode, do not clean up as we will package
                    stage("RHEL ${LINUX_VERSION} Build - ${BUILD_TYPE}"){
                        try{
                            runner.cleanup()
                            runner.checkout("${PULL_NUMBER}")
                            runner.cmakeBuildopenenclave("${BUILD_TYPE}","${COMPILER}","${EXTRA_CMAKE_ARGS}")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        }
                    }

                    // Build package and test installation work flows, rhel is not in use but add to keep in line with ubuntu
                    /**
                    stage("RHEL ${LINUX_VERSION} Package - ${BUILD_TYPE}"){
                        try{
                            runner.openenclavepackageInstall("${BUILD_TYPE}","${COMPILER}","${EXTRA_CMAKE_ARGS}")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        } finally {
                            runner.cleanup()
                        }
                    }
                    **/

                    // Build in simulation mode 
                    stage("RHEL ${LINUX_VERSION} Build - ${BUILD_TYPE} Simulation"){
                        withEnv(["OE_SIMULATION=1"]) {
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
