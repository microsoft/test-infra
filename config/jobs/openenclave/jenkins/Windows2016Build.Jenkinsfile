// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
OE_PULL_NUMBER = env.OE_PULL_NUMBER
OE_TEST_INFRA_PULL_NUMBER = env.OE_TEST_INFRA_PULL_NUMBER ? "master" : null

// OS Version Configuration
WINDOWS_VERSION = env.WINDOWS_VERSION ?: "2016"

// Some Defaults
DOCKER_TAG = env.DOCKER_TAG ?: "latest"
BUILD_TYPE = env.BUILD_TYPE ?:"Release"
COMPILER = env.COMPILER ?: "clang-7"

// Some override for build configuration
EXTRA_CMAKE_ARGS = env.EXTRA_CMAKE_ARGS ?: ""

// LVI_mitigation
LVI_MITIGATION = env.LVI_MITIGATION ?: "ControlFlow"
LVI_MITIGATION_SKIP_TESTS = env.LVI_MITIGATION_SKIP_TESTS ?: "OFF"

pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES') 
    }
    agent { label "SGXFLC-Windows-${WINDOWS_VERSION}-Docker" }
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
        stage( 'Windows Build') {
            steps {
                //withEnv(["OE_SIMULATION=1"]) {
                    script {
                        //docker.image("openenclave/windows-${WINDOWS_VERSION}:${DOCKER_TAG}").inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                            def runner = load pwd() + '/config/jobs/openenclave/jenkins/common.groovy'
                            runner.checkout("openenclave", "${OE_PULL_NUMBER}")
                            runner.cmakeBuildOE("openenclave","${BUILD_TYPE}")
                        //}
                    }
                //}
            }
        }
    }
}
