pipeline {
    options {
        timeout(time: 180, unit: 'MINUTES')
    }

    environment {
        // Shared library config, check out common.groovy!
        SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"
        EXTRA_CMAKE_ARGS="-DLVI_MITIGATION=${params.LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${params.LVI_MITIGATION_SKIP_TESTS} -DUSE_SNMALLOC=${params.USE_SNMALLOC}"
    }

    agent {
        label "ACC-${params.LINUX_VERSION}"
    }

    stages {
        stage('Checkout') {
            steps{
                cleanWs()
                checkout scm
            }
        }

        // Run CI checks up front, no need to continue if they fail.
        stage('CI Checks') {
            steps{
                script{
                    stage("${params.LINUX_VERSION} Build - CI Checks") {
                        def runner = load pwd() + "${SHARED_LIBRARY}"

                        try{
                            runner.cleanup()
                            runner.checkout("${params.PULL_NUMBER}")
                            //runner.checkCI()
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

        // Run E2E Check if enabled
        stage('Install Prereqs (optional)') {
            steps{
                script{
                    stage("${params.LINUX_VERSION} Build - Install Prereqs") {
                        def runner = load pwd() + "${SHARED_LIBRARY}"
                        if("${params.E2E}" == "ON") {
                            stage("${params.LINUX_VERSION} Setup") {
                                try{
                                    runner.cleanup()
                                    runner.checkout("${params.PULL_NUMBER}")
                                    runner.installOpenEnclavePrereqs()
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
        stage('Build') {
            steps{
                script{
                    def runner = load pwd() + "${SHARED_LIBRARY}"

                    // Build and test in Hardware mode, do not clean up as we will package
                    stage("${params.LINUX_VERSION} Build - ${params.BUILD_TYPE}") {
                        try{
                            runner.cleanup()
                            runner.checkout("${params.PULL_NUMBER}")
                            runner.cmakeBuildopenenclave("${params.BUILD_TYPE}","${params.COMPILER}","${EXTRA_CMAKE_ARGS}")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        }
                    }

                    // Build package and test installation work flows, rhel is not in use but add to keep in line with ubuntu
                    /**
                        // Build package and test installation work flows, clean up after
                        stage("${params.LINUX_VERSION} Package - ${params.BUILD_TYPE}") {
                            try{
                                runner.openenclavepackageInstall("${params.BUILD_TYPE}","${params.COMPILER}","${EXTRA_CMAKE_ARGS}")
                            } catch (Exception e) {
                                // Do something with the exception 
                                error "Program failed, please read logs..."
                            } finally {
                                runner.cleanup()
                            }
                        }
                    */

                    // Build in simulation mode 
                    stage("${params.LINUX_VERSION} Build - ${params.BUILD_TYPE} Simulation") {
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
    post ('Clean Up') {
        always{
            cleanWs()
        }
    }
}