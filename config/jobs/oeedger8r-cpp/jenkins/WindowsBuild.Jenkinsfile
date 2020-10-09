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
BUILD_TYPE = env.BUILD_TYPE ?: "Release"

// Some override for build configuration
EXTRA_CMAKE_ARGS = env.EXTRA_CMAKE_ARGS ?: ""

pipeline {
    options {
        timeout(time: 30, unit: 'MINUTES') 
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
                script {
                    //docker.image("openenclave/windows-${WINDOWS_VERSION}:${DOCKER_TAG}").inside {
                        cleanWs()
                        checkout scm
                        def runner = load pwd() + '/config/jobs/oeedger8r-cpp/jenkins/common.groovy'
                        runner.containerClean()
                        runner.checkout("oeedger8r-cpp")
                        runner.cmakeBuild("oeedger8r-cpp","${BUILD_TYPE}")
                        cleanWs()
                    //}
                }
            }
        }
    }
}
