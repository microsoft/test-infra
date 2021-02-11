// TODO:
// 2. Switch the CI containers to openenclave dockerhub instead of oeciteam
// 3. Switch to declarative
// 4. Refactor common.groovy (has dependencies on 2 + 3)

@Library('runner')
import config.jobs.openenclave.jenkins.common.groovy

pipeline {
    options {
        timeout(time: 180, unit: 'MINUTES')
    }

    environment {
        // Shared library config, check out common.groovy!
        SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"
        EXTRA_CMAKE_ARGS="-DLVI_MITIGATION=${params.LVI_MITIGATION} -DLVI_MITIGATION_SKIP_TESTS=${params.LVI_MITIGATION_SKIP_TESTS} -DUSE_SNMALLOC=${params.USE_SNMALLOC} -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin -DCMAKE_INSTALL_PREFIX:PATH=/opt/openenclave -DCPACK_GENERATOR=DEB -Wdev"
        
        // Bug with the LVI_MITIGATION environment variable in the oesdk code base, we only need the above EXTRA_CMAKE_ARGS string so set to empty.
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
        stage('CI Checks') {
            script{
                stage("Ubuntu ${params.LINUX_VERSION} Build - CI Checks") {

                    try{
                        runner.cleanup()
                        runner.checkout("${params.PULL_NUMBER}")
                        // Purposfully commented out, please see https://github.com/openenclave/test-infra/pull/465
                        // runner.checkCI()
                    } catch (Exception e) {
                        // Do something with the exception 
                        error "Program failed, please read logs..."
                    } finally {
                        runner.cleanup()
                    }
                }
            }
        }

        // Go through Build stages
        stage('Hardware') {
            steps{
                script{
                    
                    // Task for container run, define here as this how the legacy version work
                    def task =  """
                                cmake ${WORKSPACE}/openenclave -G Ninja ${EXTRA_CMAKE_ARGS}
                                ninja -v
                                ctest --output-on-failure
                                """

                    // This is a hack, we need to migrate docker image repos and we just need the short hand 
                    // linux version for compatability with legacy docker repos as part of initial integration.
                    def lin_version = "${params.LINUX_VERSION}" == "Ubuntu-1604" ? "16.04" : "18.04"

                    stage("Ubuntu Docker ${params.LINUX_VERSION} Build - ${params.BUILD_TYPE}") {
                        try{
                            runner.cleanup()
                            runner.checkout("${params.PULL_NUMBER}") 
                            runner.ContainerRun("oeciteam/oetools-full-${lin_version}:${DOCKER_TAG}", "clang-8", task, "--cap-add=SYS_PTRACE --device /dev/sgx:/dev/sgx")
                        } catch (Exception e) {
                            // Do something with the exception 
                            error "Program failed, please read logs..."
                        } finally {
                            runner.cleanup()
                        }
                    }
                }

                script{

                    // For use with common functions
                    def runner = load pwd() + "${SHARED_LIBRARY}"

                    // Task for container run, define here as this how the legacy version work
                    def task =  """
                                cmake ${WORKSPACE}/openenclave                               \
                                    -G Ninja                                                 \
                                    -DCMAKE_BUILD_TYPE=${params.BUILD_TYPE}                  \
                                    -DCMAKE_INSTALL_PREFIX:PATH='/opt/openenclave'           \
                                    -DCPACK_GENERATOR=DEB                                    \
                                    -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin    \
                                    -Wdev
                                ninja -v
                                ninja -v package
                                sudo ninja -v install
                                cp -r /opt/openenclave/share/openenclave/samples ~/
                                cd ~/samples
                                source /opt/openenclave/share/openenclave/openenclaverc
                                for i in *; do
                                    if [ -d \${i} ]; then
                                        cd \${i}
                                        mkdir build
                                        cd build
                                        cmake ..
                                        make
                                        make run
                                        cd ../..
                                    fi
                                done
                                """

                    // This is a hack, we need to migrate docker image repos and we just need the short hand 
                    // linux version for compatability with legacy docker repos as part of initial integration.
                    def lin_version = "${params.LINUX_VERSION}" == "Ubuntu-1604" ? "16.04" : "18.04"

                    // Build and test in Hardware mode, do not clean up as we will package
                    stage("Ubuntu Docker ${params.LINUX_VERSION} Package - ${params.BUILD_TYPE}") {
                        try{
                            runner.cleanup()
                            runner.checkout("${params.PULL_NUMBER}") 
                            runner.ContainerRun("oeciteam/oetools-full-${lin_version}:${DOCKER_TAG}", "clang-8", task, "--cap-add=SYS_PTRACE --device /dev/sgx:/dev/sgx")
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

        // Go through Simulation Build stages
        stage('Simulation') {
            steps{
                script{

                    // For use with common functions
                    def runner = load pwd() + "${SHARED_LIBRARY}"

                    // Task for container run, define here as this how the legacy version work
                    def task =  """
                                cmake ${WORKSPACE}/openenclave -G Ninja ${EXTRA_CMAKE_ARGS}
                                ninja -v
                                ctest --output-on-failure
                                """

                    // This is a hack, we need to migrate docker image repos and we just need the short hand 
                    // linux version for compatability with legacy docker repos as part of initial integration.
                    def lin_version = "${params.LINUX_VERSION}" == "Ubuntu-1604" ? "16.04" : "18.04"

                    // Build and test in Simulation mode
                    stage("Ubuntu Docker ${params.LINUX_VERSION} Simulation - ${params.BUILD_TYPE} Simulation") {
                        withEnv(["OE_SIMULATION=1"]) {
                            try{
                                runner.cleanup()
                                runner.checkout("${params.PULL_NUMBER}") 
                                runner.ContainerRun("oeciteam/oetools-full-${lin_version}:${DOCKER_TAG}", "clang-8", task, "--cap-add=SYS_PTRACE")
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