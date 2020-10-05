// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
PULL_NUMBER = env.PULL_NUMBER
TEST_INFRA = env.TEST_INFRA
TEST_INFRA ? PULL_NUMBER = "master" : null

// Some Defaults
BUILD_TYPE = env.BUILD_TYPE ?: "Release"

pipeline {
    agent { label 'ACC-RHEL-8' }
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
        stage('RHEL 8 Build') {
            steps {
                script {
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + '/config/jobs/oeedger8r-cpp/jenkins/common.groovy'
                    runner.checkout("oeedger8r-cpp")
                    runner.cmakeBuild("oeedger8r-cpp","${BUILD_TYPE}")
                    cleanWs()
                }
            }
        }
    }
}
