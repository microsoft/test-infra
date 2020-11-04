// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
OE_PULL_NUMBER = env.OE_PULL_NUMBER
OE_TEST_INFRA_PULL_NUMBER = env.OE_TEST_INFRA_PULL_NUMBER ? "master" : null

// Some Defaults
BUILD_TYPE = env.BUILD_TYPE ?: "Release"

pipeline {
    options {
        timeout(time: 30, unit: 'MINUTES') 
    }
    agent { label 'ACC-RHEL-8' }
    stages {
        stage('RHEL 8 Build') {
            steps {
                script {
                    cleanWs()
                    checkout scm
                    def runner = load pwd() + '/config/jobs/oeedger8r-cpp/jenkins/common.groovy'
                    runner.checkout("oeedger8r-cpp", "${OE_PULL_NUMBER}")
                    runner.cmakeBuild("oeedger8r-cpp","${BUILD_TYPE}")
                }
            }
        }
    }
}
