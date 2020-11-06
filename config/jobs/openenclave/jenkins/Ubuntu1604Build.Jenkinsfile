// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
OE_PULL_NUMBER=env.OE_PULL_NUMBER?env.OE_PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"1604"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
BUILD_TYPE=env.BUILD_TYPE?env.BUILD_TYPE:"Release"

// Some override for build configuration
EXTRA_CMAKE_ARGS = env.EXTRA_CMAKE_ARGS?env.EXTRA_CMAKE_ARGS:""

// Repo hardcoded
REPO="openenclave"

pipeline {
    options {
        timeout(time: 30, unit: 'MINUTES') 
    }
    agent { label "ACC-${LINUX_VERSION}" }
    stages {
        stage( 'Ubuntu 1604 Build') {
            steps {
                script {
                    //docker.image("openenclave/windows-${WINDOWS_VERSION}:${DOCKER_TAG}").inside {
                        cleanWs()
                        checkout scm
                        def runner = load pwd() + '/config/jobs/oeedger8r-cpp/jenkins/common.groovy'
                        runner.checkout("${REPO}", "${OE_PULL_NUMBER}")
                        runner.cmakeBuild("${REPO}","${BUILD_TYPE}")
                    //}
                }
            }
        }
    }
}
