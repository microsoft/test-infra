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
    options {
        timeout(time: 30, unit: 'MINUTES') 
    }
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
                    def runner = load pwd() + '/config/jobs/openenclave/jenkins/common.groovy'
                    runner.checkout("openenclave")
                    runner.cmakeBuild("openenclave","${BUILD_TYPE}")
                    cleanWs()
                }
            }
        }
    }
}
