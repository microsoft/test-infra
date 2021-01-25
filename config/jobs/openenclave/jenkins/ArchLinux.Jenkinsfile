pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES')
    }

    environment {
        // Shared library config, check out common.groovy!
        SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"
        EXTRA_CMAKE_ARGS="-DLVI_MITIGATION=${params.LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${params.LVI_MITIGATION_SKIP_TESTS} -DUSE_SNMALLOC=${params.USE_SNMALLOC}"
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
                                            -Wdev
                                            ninja -v
                                        """
                            runner.ContainerRun("oeciteam/oetools-full-18.04", "cross", task, "--cap-add=SYS_PTRACE")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
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
