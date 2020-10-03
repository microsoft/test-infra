CTEST_TIMEOUT_SECONDS = 480
PULL_NUMBER = env.PULL_NUMBER
TEST_INFRA = env.TEST_INFRA
TEST_INFRA ? PULL_NUMBER = "master" : null
LINUX_VERSION = env.LINUX_VERSION ?: "18.04"
WINDOWS_VERSION = env.WINDOWS_VERSION ?: "2019"
DOCKER_TAG = env.DOCKER_TAG ?: "latest"
COMPILER = env.COMPILER ?: "clang-7"
BUILD_TYPE = env.BUILD_TYPE? : "Release"
LVI_MITIGATION = env.LVI_MITIGATION? : "ControlFlow"

pipeline {
    agent { label 'ACC-1804' }
    stages {
        /* Compile tests in SGX machine.  This will generate the necessary certs for the
        * host_verify test.
        */
        //TODO: move to AKS
        stage("Ubuntu ${LINUX_VERSION} SGX1 ${COMPILER} ${BUILD_TYPE} LVI_MITIGATION=${LVI_MITIGATION}") {
            agent { label 'ACC-1804' }
            // This needs to be non sgx.. maybe
            steps{
                timeout(GLOBAL_TIMEOUT_MINUTES) {
                    cleanWs()
                    checkout scm
                    def task = """
                            cmake ${WORKSPACE}                                           \
                                -G Ninja                                                 \
                                -DCMAKE_BUILD_TYPE=${build_type}                         \
                                -DHAS_QUOTE_PROVIDER=ON                                  \
                                -DLVI_MITIGATION=${lvi_mitigation}                       \
                                -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin    \
                                -DLVI_MITIGATION_SKIP_TESTS=${lvi_mitigation_skip_tests} \
                                -Wdev                                                    \
                                ${extra_cmake_args.join(' ')}
                            ninja -v
                            """
                    oe.ContainerRun("oetools-full-${LINUX_VERSION}:${DOCKER_TAG}", compiler, task, "--cap-add=SYS_PTRACE")
                    stash includes: 'build/tests/**', name: "linux-${label}-${compiler}-${build_type}-lvi_mitigation=${lvi_mitigation}-${LINUX_VERSION}-${BUILD_NUMBER}"
                }
            }
        }

        //TODO: move to AKS
        /* Compile the tests with HAS_QUOTE_PROVIDER=OFF and unstash the certs over for verification.  */
        stage("Linux nonSGX Verify Quote") {
            agent { label 'ACC-1804' }
            steps{
                timeout(GLOBAL_TIMEOUT_MINUTES) {
                    script{
                        cleanWs()
                        checkout_linux("openenclave","openenclave")
                        unstash "linux_host_verify-${LINUX_VERSION}-${BUILD_TYPE}-${BUILD_NUMBER}"
                        def task = """
                                cmake ${WORKSPACE}/openenclave -G Ninja -DBUILD_ENCLAVES=OFF -DHAS_QUOTE_PROVIDER=OFF -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -Wdev
                                ninja -v
                                ctest -R host_verify --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
                                """
                        // Note: Include the commands to build and run the quote verification test above
                        ContainerRun("oeciteam/oetools-full-18.04-${LINUX_VERSION}:latest", "clang-7", task, "--cap-add=SYS_PTRACE")
                    }
                }
            }
        }

        /* Windows nonSGX stage. */
        stage("Windows nonSGX Verify Quote") {
            agent { label "SGXFLC-Windows-2019-Docker" }
            steps {
                timeout(GLOBAL_TIMEOUT_MINUTES) {
                    script{
                        docker.image('openenclave/windows-2019:latest').inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                            cleanWs()
                            checkout_windows("openenclave","openenclave")
                            unstash "linux_host_verify-${LINUX_VERSION}-${BUILD_TYPE}-${BUILD_NUMBER}"
                            dir('build') {
                                bat """
                                    vcvars64.bat x64 && \
                                    cmake.exe ${WORKSPACE}/openenclave -G Ninja -DBUILD_ENCLAVES=OFF -DHAS_QUOTE_PROVIDER=OFF -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DNUGET_PACKAGE_PATH=C:/oe_prereqs -Wdev && \
                                    ninja -v && \
                                    ctest.exe -V -C ${BUILD_TYPE} -R host_verify --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
                                    """
                            }
                        }
                    }
                }
            }
        }
    }
}

void checkout_linux(String REPO_OWNER, String REPO_NAME ) {
    sh  """
        rm -rf ${REPO_NAME} && \
        git clone https://github.com/${REPO_OWNER}/${REPO_NAME} && \
        cd ${REPO_NAME} && \
        git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
        if [[ $PULL_NUMBER -ne 'master' ]]; then
            git checkout origin/pr/${PULL_NUMBER}
        fi
        """
}

void checkout_windows(String REPO_OWNER, String REPO_NAME ) {
    bat """
        (if exist ${REPO_NAME} rmdir /s/q ${REPO_NAME}) && \
        git clone https://github.com/${REPO_OWNER}/${REPO_NAME} && \
        cd ${REPO_NAME} && \
        git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
        if NOT ${PULL_NUMBER}==master git checkout_windows origin/pr/${PULL_NUMBER}
        """
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