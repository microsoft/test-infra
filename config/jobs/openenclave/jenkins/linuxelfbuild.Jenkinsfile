// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
PULL_NUMBER = env.PULL_NUMBER
TEST_INFRA = env.TEST_INFRA
TEST_INFRA ? PULL_NUMBER = "master" : null

// OS Version Configuration
LINUX_VERSION = env.LINUX_VERSION ?: "1804"
WINDOWS_VERSION = env.WINDOWS_VERSION ?: "2019"

// Some Defaults
DOCKER_TAG = env.DOCKER_TAG ?: "latest"
BUILD_TYPE = env.BUILD_TYPE ?:"Release"
COMPILER = env.COMPILER ?: "clang-7"

// LVI_mitigation
LVI_MITIGATION = env.LVI_MITIGATION ?: "None"
LVI_MITIGATION_SKIP_TESTS = env.LVI_MITIGATION_SKIP_TESTS ?: "OFF"

pipeline {
    agent { label "OverWatch" }
    stages {
        /* Compile tests in SGX machine.  This will generate the necessary certs for the
        * host_verify test.
        */
        //TODO: move to AKS
        stage("Ubuntu 1804 SGX1 clang-7 Release LVI_MITIGATION=ControlFlow") {
            agent { label "ACC-${LINUX_VERSION}"}
            steps{
                timeout(GLOBAL_TIMEOUT_MINUTES) {
                    script{
                        cleanWs()
                        def runner = load pwd() + '/config/jobs/openenclave/jenkins/common.groovy'
                        runner.checkout("openenclave")
                        def task = """
                                cmake ${WORKSPACE}/openenclave                               \
                                    -G Ninja                                                 \
                                    -DCMAKE_BUILD_TYPE=${BUILD_TYPE}                         \
                                    -DHAS_QUOTE_PROVIDER=ON                                  \
                                    -DLVI_MITIGATION=${LVI_MITIGATION}                       \
                                    -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin    \
                                    -DLVI_MITIGATION_SKIP_TESTS=${LVI_MITIGATION_SKIP_TESTS} \
                                    -Wdev
                                ninja -v
                                """
                        runner.ContainerRun("openenclave/ubuntu-${LINUX_VERSION}:latest", "clang-7", task, "--cap-add=SYS_PTRACE")
                        stash includes: 'build/tests/**', name: "linux-ACC-${LINUX_VERSION}-${COMPILER}-${BUILD_TYPE}-LVI_MITIGATION=${LVI_MITIGATION}-${LINUX_VERSION}-${BUILD_NUMBER}"
                    }
                }
            }
        }
        stage("Windows SGX1 clang-7 Release LVI_MITIGATION=ControlFlow") {
            agent { label "SGXFLC-Windows-${WINDOWS_VERSION}-Docker" }
            steps {
                timeout(GLOBAL_TIMEOUT_MINUTES) {
                    script{
                        cleanWs()
                        def runner = load pwd() + '/config/jobs/openenclave/jenkins/common.groovy'
                        runner.checkout("openenclave")
                        unstash "linux-ACC-${LINUX_VERSION}-${COMPILER}-${BUILD_TYPE}-LVI_MITIGATION=${LVI_MITIGATION}-${LINUX_VERSION}-${BUILD_NUMBER}"
                        bat 'move build linuxbin'
                        dir('build') {
                        bat """
                            vcvars64.bat x64 && \
                            cmake.exe ${WORKSPACE}\\openenclave -G Ninja -DADD_WINDOWS_ENCLAVE_TESTS=ON -DBUILD_ENCLAVES=OFF -DHAS_QUOTE_PROVIDER=ON -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DLINUX_BIN_DIR=${WORKSPACE}\\linuxbin\\tests -DLVI_MITIGATION=${LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${LVI_MITIGATION_SKIP_TESTS} -DNUGET_PACKAGE_PATH=C:/oe_prereqs -Wdev && \
                            ninja -v && \
                            ctest.exe -V -C ${BUILD_TYPE} --timeout ${CTEST_TIMEOUT_SECONDS}
                            """
                        }
                    }
                }
            }
        }
    }
}
