pipeline {
    options {
        timeout(time: 180, unit: 'MINUTES')
    }

    environment {
        // Shared library config, check out common.groovy!
        SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"
        EXTRA_CMAKE_ARGS="-DLVI_MITIGATION=${params.LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${params.LVI_MITIGATION_SKIP_TESTS} -DUSE_SNMALLOC=${params.USE_SNMALLOC} -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin -DCMAKE_INSTALL_PREFIX:PATH=/opt/openenclave -DCPACK_GENERATOR=DEB -Wdev"
        // Bug with the environment variable, we only need the above string so set to empty
        LVI_MITIGATION=""
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
        stage('Dev Flows Check') {
            steps{
                script{
                    stage("Ubuntu ${params.LINUX_VERSION} Build - CI Checks") {
                        def runner = load pwd() + "${SHARED_LIBRARY}"

                        try{
                            runner.cleanup()
                            runner.checkout("${params.PULL_NUMBER}")
                            runner.checkDevFlows()
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

        // Go through Build stages
        stage('Build') {
            steps{
                script{
                    def runner = load pwd() + "${SHARED_LIBRARY}"

                    // Build and test in Hardware mode, do not clean up as we will package
                    stage("Ubuntu ${params.LINUX_VERSION} Build - ${params.BUILD_TYPE}") {
                        try{
                            runner.cleanup()
                            runner.checkout("${params.PULL_NUMBER}")
                            runner.cmakeBuildopenenclave("${params.BUILD_TYPE}","${params.COMPILER}","${EXTRA_CMAKE_ARGS}")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        }
                    }

                    // Build in simulation mode 
                    stage("Ubuntu ${params.LINUX_VERSION} Build - ${params.BUILD_TYPE} Simulation") {
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