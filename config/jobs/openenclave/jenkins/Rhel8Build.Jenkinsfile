// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
OE_PULL_NUMBER=env.OE_PULL_NUMBER?env.OE_PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"RHEL-8"

// Some Defaults
BUILD_MODE=env.BUILD_MODE?env.BUILD_MODE:"hardware"
String[] BUILD_TYPES = ['Debug', 'RelWithDebInfo', 'Release']


// Some override for build configuration
EXTRA_CMAKE_ARGS = env.EXTRA_CMAKE_ARGS?env.EXTRA_CMAKE_ARGS:""
COMPILER=env.COMPILER?env.COMPILER:"clang-8"

// Repo hardcoded
REPO="openenclave"

// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/"+"${REPO}"+"/jenkins/common.groovy"

pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES') 
    }
    agent { label "ACC-${LINUX_VERSION}" }

    stages {
        stage('Build'){
            steps{
                script{
                    for(BUILD_TYPE in BUILD_TYPES){
                        stage("${LINUX_VERSION} Build - ${BUILD_TYPE}"){
                            script {
                                cleanWs()
                                checkout scm
                                def runner = load pwd() + "${SHARED_LIBRARY}"
                                runner.cleanup("${REPO}")
                                try{
                                    runner.checkout("${REPO}", "${OE_PULL_NUMBER}")
                                    runner.cmakeBuildPackageOESim("${REPO}","${BUILD_TYPE}", "${EXTRA_CMAKE_ARGS}", "${COMPILER}")
                                } catch (Exception e) {
                                    // Do something with the exception 
                                    error "Program failed, please read logs..."
                                } finally {
                                    runner.cleanup("${REPO}")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}