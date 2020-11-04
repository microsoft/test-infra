// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
OE_PULL_NUMBER = env.OE_PULL_NUMBER
OE_TEST_INFRA_PULL_NUMBER = env.OE_TEST_INFRA_PULL_NUMBER ? "master" : null

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
    options {
        timeout(time: 60, unit: 'MINUTES') 
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
                    def runner = load pwd() + '/config/jobs/openenclave/jenkins/common.groovy'
                    runner.checkout("openenclave", "${OE_PULL_NUMBER}")
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
                    ContainerRun("openenclave/ubuntu-${LINUX_VERSION}:latest", "clang-7", task, "--cap-add=SYS_PTRACE")
                    stash includes: 'build/tests/**', name: "linux-ACC-${LINUX_VERSION}-${COMPILER}-${BUILD_TYPE}-LVI_MITIGATION=${LVI_MITIGATION}-${LINUX_VERSION}-${BUILD_NUMBER}"
                }
            }
        }
        stage("Windows SGX1 clang-7 Release LVI_MITIGATION=ControlFlow") {
            agent { label "SGXFLC-Windows-2019-Docker" }
            steps {
                script {
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + '/config/jobs/openenclave/jenkins/common.groovy'
                    runner.checkout("openenclave", "${OE_PULL_NUMBER}")
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

void checkout2( String REPO_NAME , String OE_PULL_NUMBER) {
    if (isUnix()) {
        sh  """
            rm -rf ${REPO_NAME} && \
            git clone --recursive --depth 1 https://github.com/openenclave-ci/${REPO_NAME} && \
            cd ${REPO_NAME} && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if [[ ${OE_PULL_NUMBER} -ne 'master' ]]; then
                git checkout origin/pr/${OE_PULL_NUMBER}
            fi
            """
    }
    else {
        bat """
            (if exist ${REPO_NAME} rmdir /s/q ${REPO_NAME}) && \
            git clone --recursive --depth 1 https://github.com/openenclave-ci/${REPO_NAME} && \
            cd ${REPO_NAME} && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if NOT ${OE_PULL_NUMBER}==master git checkout origin/pr/${OE_PULL_NUMBER}
            """
    }
}

def ContainerRun(String imageName, String compiler, String task, String runArgs="") {
    def image = docker.image(imageName)
    image.pull()
    image.inside(runArgs) {
        dir("${WORKSPACE}/openenclave/build") {
            Run(compiler, task)
        }
    }
}

def runTask(String task) {
    dir("${WORKSPACE}/build") {
        sh """#!/usr/bin/env bash
                set -o errexit
                set -o pipefail
                source /etc/profile
                ${task}
            """
    }
}

def Run(String compiler, String task, String compiler_version = "") {
    def c_compiler
    def cpp_compiler
    switch(compiler) {
        case "cross":
            // In this case, the compiler is set by the CMake toolchain file. As
            // such, it is not necessary to specify anything in the environment.
            runTask(task)
            return
        case "clang-7":
            c_compiler = "clang"
            cpp_compiler = "clang++"
            compiler_version = "7"
            break
        case "gcc":
            c_compiler = "gcc"
            cpp_compiler = "g++"
            break
        default:
            // This is needed for backwards compatibility with the old
            // implementation of the method.
            c_compiler = "clang"
            cpp_compiler = "clang++"
            compiler_version = "8"
    }
    if (compiler_version) {
        c_compiler += "-${compiler_version}"
        cpp_compiler += "-${compiler_version}"
    }
    withEnv(["CC=${c_compiler}","CXX=${cpp_compiler}"]) {
        runTask(task);
    }
}
