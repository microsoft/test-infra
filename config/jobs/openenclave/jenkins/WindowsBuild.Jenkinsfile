pipeline {
    options {
        timeout(time: 180, unit: 'MINUTES')
    }

    parameters {
        string(name: 'WINDOWS_VERSION', defaultValue: params.WINDOWS_VERSION ?:'Windows-2019', description: 'Windows version to build')
        string(name: 'COMPILER', defaultValue: params.COMPILER ?:'MSVC', description: 'Compiler version')
        string(name: 'DOCKER_TAG', defaultValue: params.DOCKER_TAG ?:'latest', description: 'Docker image version')
        string(name: 'PULL_NUMBER', defaultValue: params.PULL_NUMBER ?:'master',  description: 'Branch/PR to build')
        string(name: 'BUILD_TYPE', defaultValue: params.BUILD_TYPE ?:'RelWithDebInfo',  description: 'Build Type')
        string(name: 'LVI_MITIGATION', defaultValue: params.LVI_MITIGATION ?:'ControlFlow',  description: 'LVI Mitigation Strategy')
        string(name: 'LVI_MITIGATION_SKIP_TESTS', defaultValue: params.LVI_MITIGATION_SKIP_TESTS ?:'OFF',  description: 'Skip LVI_MITIGATION_SKIP_TESTS')
        string(name: 'USE_SNMALLOC', defaultValue: params.USE_SNMALLOC ?:'ON',  description: 'Use snmalloc for buiild')
        string(name: 'E2E', defaultValue: params.E2E ?:'OFF',  description: 'End to en set up')
    }

    environment {
        // Shared library config, check out common.groovy!
        SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"
        // TOFO: Refactor this into common groovy
        EXTRA_CMAKE_ARGS="-DLVI_MITIGATION=${params.LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${params.LVI_MITIGATION_SKIP_TESTS} -DUSE_SNMALLOC=${params.USE_SNMALLOC}"
    }

    agent {
        label "ACC-${WINDOWS_VERSION}"
    }

    stages {
        stage('Checkout') {
            steps{
                cleanWs()
                checkout scm
            }
        }

        stage('Install Prereqs (optional)') {
            steps{
                script{
                    stage("${params.WINDOWS_VERSION} Build - Install Prereqs"){
                        def runner = load pwd() + "${SHARED_LIBRARY}"
                        if("${params.E2E}" == "ON"){
                            stage("${WINDOWS_VERSION} Setup"){
                                try{
                                    runner.cleanup()
                                    runner.checkout("${PULL_NUMBER}")
                                    // TODO: Windows is not currently working for E2E
                                    //runner.installOpenEnclavePrereqs()
                                } catch (Exception e) {
                                    // Do something with the exception 
                                    error "Program failed, please read logs..."
                                }
                            }
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
                    stage("${params.WINDOWS_VERSION} Build - ${params.BUILD_TYPE}"){
                        try{
                            runner.cleanup()
                            runner.checkout("${params.PULL_NUMBER}")
                            runner.cmakeBuildopenenclave("${params.BUILD_TYPE}","${params.COMPILER}","${EXTRA_CMAKE_ARGS}")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        }
                    }

                    // Build package and test installation work flows, clean up after
                    stage("${params.WINDOWS_VERSION} Package - ${params.BUILD_TYPE}"){
                        try{
                            runner.openenclavepackageInstall("${params.BUILD_TYPE}","${params.COMPILER}","${EXTRA_CMAKE_ARGS}")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        } finally {
                            runner.cleanup()
                        }
                    }

                    // Build in simulation mode 
                    stage("${params.WINDOWS_VERSION} Build - ${params.BUILD_TYPE} Simulation"){
                        withEnv(["OE_SIMULATION=1"]) {
                            try{
                                runner.cleanup()
                                runner.checkout("${params.PULL_NUMBER}")
                                runner.cmakeBuildopenenclave("${params.BUILD_TYPE}","${params.COMPILER}","${EXTRA_CMAKE_ARGS}")
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
