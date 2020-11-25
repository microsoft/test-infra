// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
OE_PULL_NUMBER=env.OE_PULL_NUMBER?env.OE_PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"1804"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
BUILD_MODE=env.BUILD_MODE?env.BUILD_MODE:"hardware"
String[] BUILD_TYPES = ['Debug', 'RelWithDebInfo', 'Release']

// Some override for build configuration
EXTRA_CMAKE_ARGS=env.EXTRA_CMAKE_ARGS?env.EXTRA_CMAKE_ARGS:"-DLVI_MITIGATION=ControlFlow -DLVI_MITIGATION_SKIP_TESTS=OFF -DUSE_SNMALLOC=ON"

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
                        stage("Ubuntu 1804 Build - ${BUILD_TYPE}"){
                            script {
                                cleanWs()
                                checkout scm
                                def runner = load pwd() + "${SHARED_LIBRARY}"
                                runner.cleanup("${REPO}")
                                try{
                                    runner.checkout("${REPO}", "${OE_PULL_NUMBER}")
                                    runner.cmakeBuildPackageInstallOE("${REPO}","${BUILD_TYPE}", "${EXTRA_CMAKE_ARGS}")
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