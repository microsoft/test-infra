// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
OE_PULL_NUMBER=env.OE_PULL_NUMBER?env.OE_PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"Ubuntu-1804"
WINDOWS_VERSION=env.WINDOWS_VERSION?env.WINDOWS_VERSION:"Windows-2019"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
BUILD_TYPE=env.BUILD_TYPE?env.BUILD_TYPE:"Release"
COMPILER= env.COMPILER?env.COMPILER:"clang-7"

// LVI_mitigation
LVI_MITIGATION=env.LVI_MITIGATION?:"ControlFlow"
LVI_MITIGATION_SKIP_TESTS= env.LVI_MITIGATION_SKIP_TESTS?:"OFF"

// Repo hardcoded
REPO="openenclave"

// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/"+"${REPO}"+"/jenkins/common.groovy"

pipeline {
    options {
        timeout(time: 120, unit: 'MINUTES') 
    }
    agent { label "OverWatch" }
    stages {
        /* Compile tests in SGX machine.  This will generate the necessary certs for the
        * host_verify test.
        */
        //TODO: move to AKS
        stage("Ubuntu 1804 SGX1 clang-7 Release LVI_MITIGATION=ControlFlow") {
            agent { label "ACC-${LINUX_VERSION}"}
            steps{
                script {
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    runner.checkout("${OE_PULL_NUMBER}")
                    def task = """
                            cmake ${WORKSPACE}/openenclave                               \
                                -G Ninja                                                 \
                                -DCMAKE_BUILD_TYPE=${BUILD_TYPE}                         \
                                -DLVI_MITIGATION=${LVI_MITIGATION}                       \
                                -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin    \
                                -DLVI_MITIGATION_SKIP_TESTS=${LVI_MITIGATION_SKIP_TESTS} \
                                -Wdev
                            ninja -v
                            """
                    runner.ContainerRun("openenclave/ubuntu-1804:latest", "clang-7", task, "--cap-add=SYS_PTRACE")
                    stash includes: 'build/tests/**', name: "linux-ACC-${LINUX_VERSION}-${COMPILER}-${BUILD_TYPE}-LVI_MITIGATION=${LVI_MITIGATION}-${LINUX_VERSION}-${BUILD_NUMBER}"
                }
            }
        }
        stage("Windows SGX1 clang-7 Release LVI_MITIGATION=ControlFlow") {
            agent { label "ACC-${WINDOWS_VERSION}" }
            steps {
                script {
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    runner.checkout("${OE_PULL_NUMBER}")
                    unstash "linux-ACC-${LINUX_VERSION}-${COMPILER}-${BUILD_TYPE}-LVI_MITIGATION=${LVI_MITIGATION}-${LINUX_VERSION}-${BUILD_NUMBER}"
                    bat 'move build linuxbin'
                    dir('build') {
                    bat """
                        vcvars64.bat x64 && \
                        cmake.exe ${WORKSPACE}\\openenclave -G Ninja -DADD_WINDOWS_ENCLAVE_TESTS=ON -DBUILD_ENCLAVES=OFF -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DLINUX_BIN_DIR=${WORKSPACE}\\linuxbin\\tests -DLVI_MITIGATION=${LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${LVI_MITIGATION_SKIP_TESTS} -DNUGET_PACKAGE_PATH=C:/oe_prereqs -Wdev && \
                        ninja -v && \
                        ctest.exe -V -C ${BUILD_TYPE} --timeout ${CTEST_TIMEOUT_SECONDS}
                        """
                    }
                }
            }
        }
    }
}
