pipeline {
    options {
        timeout(time: 120, unit: 'MINUTES') 
    }

    environment {
        // Shared library config, check out common.groovy!
        SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"
    }

    agent { label "OverWatch" }
    stages {
        /* Compile tests in SGX machine.  This will generate the necessary certs for the
        * host_verify test.
        */
        stage("Ubuntu 1804 SGX1 clang-7 Release params.LVI_MITIGATION=ControlFlow") {
            agent { label "ACC-${params.LINUX_VERSION}"}
            steps{
                script {
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    runner.checkout("${params.PULL_NUMBER}")
                    def task = """
                            cmake ${WORKSPACE}/openenclave                               \
                                -G Ninja                                                 \
                                -DCMAKE_params.BUILD_TYPE=${params.BUILD_TYPE}                         \
                                -DHAS_QUOTE_PROVIDER=ON                                  \
                                -Dparams.LVI_MITIGATION=${params.LVI_MITIGATION}                       \
                                -Dparams.LVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin    \
                                -Dparams.LVI_MITIGATION_SKIP_TESTS=${params.LVI_MITIGATION_SKIP_TESTS} \
                                -Wdev
                            ninja -v
                            """
                    runner.ContainerRunLegacy("openenclave/ubuntu-1804:latest", "clang-7", task, "--cap-add=SYS_PTRACE")
                    stash includes: 'build/tests/**', name: "linux-ACC-${params.LINUX_VERSION}-${params.COMPILER}-${params.BUILD_TYPE}-params.LVI_MITIGATION=${params.LVI_MITIGATION}-${params.LINUX_VERSION}-${BUILD_NUMBER}"
                }
            }
        }
        stage("Windows SGX1 clang-7 Release params.LVI_MITIGATION=ControlFlow") {
            agent { label "ACC-${params.WINDOWS_VERSION}" }
            steps {
                script {
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    runner.checkout("${params.PULL_NUMBER}")
                    unstash "linux-ACC-${params.LINUX_VERSION}-${params.COMPILER}-${params.BUILD_TYPE}-params.LVI_MITIGATION=${params.LVI_MITIGATION}-${params.LINUX_VERSION}-${BUILD_NUMBER}"
                    bat 'move build linuxbin'
                    dir('build') {
                    bat """
                        vcvars64.bat x64 && \
                        cmake.exe ${WORKSPACE}\\openenclave -G Ninja -DADD_WINDOWS_ENCLAVE_TESTS=ON -DBUILD_ENCLAVES=OFF -DHAS_QUOTE_PROVIDER=ON -DCMAKE_params.BUILD_TYPE=${params.BUILD_TYPE} -DLINUX_BIN_DIR=${WORKSPACE}\\linuxbin\\tests -Dparams.LVI_MITIGATION=${params.LVI_MITIGATION} -Dparams.LVI_MITIGATION_SKIP_TESTS=${params.LVI_MITIGATION_SKIP_TESTS} -DNUGET_PACKAGE_PATH=C:/oe_prereqs -Wdev && \
                        ninja -v && \
                        ctest.exe -V -C ${params.BUILD_TYPE} --timeout 1200
                        """
                    }
                }
            }
        }
    }
}
