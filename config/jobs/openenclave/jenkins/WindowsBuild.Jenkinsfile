// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
PULL_NUMBER = env.PULL_NUMBER
TEST_INFRA = env.TEST_INFRA
TEST_INFRA ? PULL_NUMBER = "master" : null

// OS Version Configuration
WINDOWS_VERSION = env.WINDOWS_VERSION ?: "2019"

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
                script {
                    //docker.image("openenclave/windows-${WINDOWS_VERSION}:${DOCKER_TAG}").inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                        def runner = load pwd() + '/config/jobs/openenclave/jenkins/common.groovy'
                        runner.checkout("openenclave")
                        runner.cmakeBuildOE("openenclave","${BUILD_TYPE}")
                    //}
                }
            }
        }
    }
}
