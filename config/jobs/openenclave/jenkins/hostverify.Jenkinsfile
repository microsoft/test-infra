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

pipeline {
    options {
        timeout(time: 30, unit: 'MINUTES') 
    }
    agent { label "OverWatch" }
    stages {
        // Double Clen Base Environments just in case
        stage( 'Sanitize Build Environment') {
            steps {
                script {
                    cleanWs()
                    checkout scm
                }
            }
        }
        /* Compile tests in SGX machine.  This will generate the necessary certs for the
        * host_verify test.
        */
        //TODO: move to AKS
        stage("ACC-1804 Generate Quote") {
            agent { label "ACC-${LINUX_VERSION}"}
            steps{
                timeout(GLOBAL_TIMEOUT_MINUTES) {
                    script{
                        cleanWs()
                        checkout("openenclave")

                        println("Generating certificates and reports ...")
                        def task = """
                                cmake ${WORKSPACE}/openenclave -G Ninja -DHAS_QUOTE_PROVIDER=ON -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -Wdev
                                ninja -v
                                pushd tests/host_verify/host
                                openssl ecparam -name prime256v1 -genkey -noout -out keyec.pem
                                openssl ec -in keyec.pem -pubout -out publicec.pem
                                openssl genrsa -out keyrsa.pem 2048
                                openssl rsa -in keyrsa.pem -outform PEM -pubout -out publicrsa.pem
                                ../../tools/oecert/host/oecert ../../tools/oecert/enc/oecert_enc --cert keyec.pem publicec.pem --out sgx_cert_ec.der
                                ../../tools/oecert/host/oecert ../../tools/oecert/enc/oecert_enc --cert keyrsa.pem publicrsa.pem --out sgx_cert_rsa.der
                                ../../tools/oecert/host/oecert ../../tools/oecert/enc/oecert_enc --report --out sgx_report.bin
                                popd
                                """
                        ContainerRun("openenclave/ubuntu-${LINUX_VERSION}:latest", "clang-7", task, "--cap-add=SYS_PTRACE --device /dev/sgx:/dev/sgx")

                        def ec_cert_created = fileExists 'build/tests/host_verify/host/sgx_cert_ec.der'
                        def rsa_cert_created = fileExists 'build/tests/host_verify/host/sgx_cert_rsa.der'
                        def report_created = fileExists 'build/tests/host_verify/host/sgx_report.bin'
                        if (ec_cert_created) {
                            println("EC cert file created successfully!")
                        } else {
                            error("Failed to create EC cert file.")
                        }
                        if (rsa_cert_created) {
                            println("RSA cert file created successfully!")
                        } else {
                            error("Failed to create RSA cert file.")
                        }
                        if (report_created) {
                            println("SGX report file created successfully!")
                        } else {
                            error("Failed to create SGX report file.")
                        }

                        stash includes: 'build/tests/host_verify/host/*.der,build/tests/host_verify/host/*.bin', name: "linux_host_verify-${LINUX_VERSION}-${BUILD_TYPE}-${BUILD_NUMBER}"
                    }
                }
            }
        }

        //TODO: move to AKS
        /* Compile the tests with HAS_QUOTE_PROVIDER=OFF and unstash the certs over for verification.  */
        stage("Linux nonSGX Verify Quote") {
            agent { label "ACC-${LINUX_VERSION}"}
            steps{
                timeout(GLOBAL_TIMEOUT_MINUTES) {
                    script{
                        cleanWs()
                        checkout("openenclave")
                        unstash "linux_host_verify-${LINUX_VERSION}-${BUILD_TYPE}-${BUILD_NUMBER}"
                        def task = """
                                cmake ${WORKSPACE}/openenclave -G Ninja -DBUILD_ENCLAVES=OFF -DHAS_QUOTE_PROVIDER=OFF -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -Wdev
                                ninja -v
                                ctest -R host_verify --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
                                """
                        // Note: Include the commands to build and run the quote verification test above
                        ContainerRun("openenclave/ubuntu-${LINUX_VERSION}:latest", "clang-7", task, "--cap-add=SYS_PTRACE")
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
                        cleanWs()
                        checkout("openenclave")
                        docker.image('openenclave/windows-2019:latest').inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
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

void checkout( String REPO_NAME ) {
    if (isUnix()) {
        sh  """
            rm -rf ${REPO_NAME} && \
            git clone --recursive --depth 1 https://github.com/openenclave/${REPO_NAME} && \
            cd ${REPO_NAME} && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if [[ $PULL_NUMBER -ne 'master' ]]; then
                git checkout origin/pr/${PULL_NUMBER}
            fi
            """
    }
    else {
        bat """
            (if exist ${REPO_NAME} rmdir /s/q ${REPO_NAME}) && \
            git clone --recursive --depth 1 https://github.com/openenclave/${REPO_NAME} && \
            cd ${REPO_NAME} && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if NOT ${PULL_NUMBER}==master git checkout origin/pr/${PULL_NUMBER}
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