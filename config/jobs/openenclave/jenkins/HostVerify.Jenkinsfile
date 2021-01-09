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
        stage("ACC-1804 Generate Quote") {
            agent { label "ACC-${LINUX_VERSION}"}
            steps{
                script{
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    runner.checkout("${OE_PULL_NUMBER}")
                    println("Generating certificates and reports ...")
                    def task = """
                            cmake ${WORKSPACE}/openenclave -G Ninja -DHAS_QUOTE_PROVIDER=ON -DCMAKE_BUILD_TYPE=${build_type} -Wdev
                            ninja -v
                            pushd tests/host_verify/host
                            openssl ecparam -name prime256v1 -genkey -noout -out keyec.pem
                            openssl ec -in keyec.pem -pubout -out publicec.pem
                            openssl genrsa -out keyrsa.pem 2048
                            openssl rsa -in keyrsa.pem -outform PEM -pubout -out publicrsa.pem
                            ../../tools/oecert/host/oecert ../../tools/oecert/enc/oecert_enc --cert keyec.pem publicec.pem --out sgx_cert_ec.der
                            ../../tools/oecert/host/oecert ../../tools/oecert/enc/oecert_enc --cert keyrsa.pem publicrsa.pem --out sgx_cert_rsa.der
                            ../../tools/oecert/host/oecert ../../tools/oecert/enc/oecert_enc --report --out sgx_report.bin
                            ../../tools/oecert/host/oecert ../../tools/oecert/enc/oecert_enc --evidence --out sgx_evidence.bin --endorsements sgx_endorsements.bin
                            popd
                            """
                    runner.ContainerRun("openenclave/ubuntu-1804:latest", "clang-7", task, "--cap-add=SYS_PTRACE --device /dev/sgx:/dev/sgx")

                    def ec_cert_created = fileExists 'build/tests/host_verify/host/sgx_cert_ec.der'
                    def rsa_cert_created = fileExists 'build/tests/host_verify/host/sgx_cert_rsa.der'
                    def report_created = fileExists 'build/tests/host_verify/host/sgx_report.bin'
                    def evidence_created = fileExists 'build/tests/host_verify/host/sgx_evidence.bin'
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
                    if (evidence_created) {
                        println("SGX evidence file created successfully!")
                    } else {
                        error("Failed to create SGX evidence file.")
                    }

                    stash includes: 'build/tests/host_verify/host/*.der,build/tests/host_verify/host/*.bin', name: "linux_host_verify-${LINUX_VERSION}-${BUILD_TYPE}-${BUILD_NUMBER}"
                }
            }
        }

        //TODO: move to AKS
        /* Compile the tests with HAS_QUOTE_PROVIDER=OFF and unstash the certs over for verification.  */
        stage("Linux nonSGX Verify Quote") {
            agent { label "ACC-${LINUX_VERSION}"}
            steps{
                script{
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    runner.checkout("${OE_PULL_NUMBER}")
                    unstash "linux_host_verify-${LINUX_VERSION}-${BUILD_TYPE}-${BUILD_NUMBER}"
                    def task = """
                            cmake ${WORKSPACE}/openenclave -G Ninja -DBUILD_ENCLAVES=OFF -DHAS_QUOTE_PROVIDER=OFF -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -Wdev
                            ninja -v
                            ctest -R host_verify --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
                            """
                    // Note: Include the commands to build and run the quote verification test above
                    runner.ContainerRun("openenclave/ubuntu-1804:latest", "clang-7", task, "--cap-add=SYS_PTRACE")
                }
            }
        }

        /* Windows nonSGX stage. */
        stage("Windows nonSGX Verify Quote") {
            agent { label "ACC-${WINDOWS_VERSION}" }
            steps {
                script{
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    runner.checkout("${OE_PULL_NUMBER}")
                    //docker.image('openenclave/windows-2019:latest').inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                        unstash "linux_host_verify-${LINUX_VERSION}-${BUILD_TYPE}-${BUILD_NUMBER}"
                        dir('build') {
                            bat """
                                vcvars64.bat x64 && \
                                cmake.exe ${WORKSPACE}/openenclave -G Ninja -DBUILD_ENCLAVES=OFF -DHAS_QUOTE_PROVIDER=OFF -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DNUGET_PACKAGE_PATH=C:/oe_prereqs -Wdev && \
                                ninja -v && \
                                ctest.exe -V -C ${BUILD_TYPE} -R host_verify --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
                                """
                        }
                    //}
                }
            }
        }
    }
}
