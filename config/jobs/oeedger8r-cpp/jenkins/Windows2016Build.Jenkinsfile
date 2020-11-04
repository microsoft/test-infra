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
BUILD_TYPE = env.BUILD_TYPE ?: "Release"

// Some override for build configuration
EXTRA_CMAKE_ARGS = env.EXTRA_CMAKE_ARGS ?: ""

pipeline {
    options {
        timeout(time: 30, unit: 'MINUTES') 
    }
    agent { label "SGXFLC-Windows-${WINDOWS_VERSION}-Docker" }
    stages {
        stage( 'Windows Build') {
            steps {
                script {
                    //docker.image("openenclave/windows-${WINDOWS_VERSION}:${DOCKER_TAG}").inside {
                        cleanWs()
                        checkout scm
                        def runner = load pwd() + '/config/jobs/oeedger8r-cpp/jenkins/common.groovy'
                        runner.checkout("oeedger8r-cpp","${OE_PULL_NUMBER}")
                        runner.cmakeBuild("oeedger8r-cpp","${BUILD_TYPE}")
                        cleanWs()
                    //}
                }
            }
        }
    }
}
