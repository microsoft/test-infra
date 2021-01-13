// Pull Request Information
PULL_NUMBER=env.PULL_NUMBER?env.PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"Ubuntu-1804"

// Some Defaults for general build info
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
COMPILER=env.COMPILER?env.COMPILER:"clang-7"
BUILD_TYPE=env.BUILD_TYPE?env.BUILD_TYPE:"RelWithDebInfo"

// Some override for build configuration
LVI_MITIGATION=env.LVI_MITIGATION?env.LVI_MITIGATION:"ControlFlow"
LVI_MITIGATION_SKIP_TESTS=env.LVI_MITIGATION_SKIP_TESTS?env.LVI_MITIGATION_SKIP_TESTS:"OFF"
USE_SNMALLOC=env.USE_SNMALLOC?env.USE_SNMALLOC:"ON"

// Edge casee, snmalloc will not work on old gcc versions and 1604 default is old. Remove after 1604 deprecation.
USE_SNMALLOC=expression { return COMPILER == 'gcc' && LINUX_VERSION =='1604'}?"OFF":USE_SNMALLOC

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

        // Go through Build stages
        stage('Build'){
            steps{
                script{
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    // Build and test in Hardware mode, do not clean up as we will package
                    stage("AArch64GNU ${LINUX_VERSION} Build - ${BUILD_TYPE}"){
                        try{
                            runner.cleanup()
                            runner.checkout("${PULL_NUMBER}")
                            def task =  """
                                        cmake ${WORKSPACE}/openenclave                                              \
                                            -G Ninja                                                                \
                                            -DCMAKE_BUILD_TYPE=${BUILD_TYPE}                                        \
                                            -DCMAKE_TOOLCHAIN_FILE=${WORKSPACE}/openenclave/cmake/arm-cross.cmake   \
                                            -DOE_TA_DEV_KIT_DIR=/devkits/vexpress-qemu_armv8a/export-ta_arm64       \
                                            -DHAS_QUOTE_PROVIDER=OFF                                                \
                                            -Wdev
                                            ninja -v
                                        echo 'here'
                                        ls -l
                                        """
                            runner.ContainerRun("oeciteam/oetools-full-18.04", "cross", task, "--cap-add=SYS_PTRACE")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        }
                    }

                    // Build package and test installation work flows, clean up after
                    stage("Ubuntu ${LINUX_VERSION} Package - ${BUILD_TYPE}"){
                        try{
                            runner.openenclavepackageInstall("${BUILD_TYPE}","${COMPILER}","${EXTRA_CMAKE_ARGS}")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        } finally {
                            runner.cleanup()
                        }
                    }

                    // Build in simulation mode 
                    stage("Ubuntu ${LINUX_VERSION} Build - ${BUILD_TYPE} Simulation"){
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
