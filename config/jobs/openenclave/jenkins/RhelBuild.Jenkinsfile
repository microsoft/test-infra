// Pull Request Information
PULL_NUMBER=env.PULL_NUMBER?env.PULL_NUMBER:"master"

// OS Version Configuration
LINUX_VERSION=env.LINUX_VERSION?env.LINUX_VERSION:"8"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
COMPILER=env.COMPILER?env.COMPILER:"gcc"
//String[] BUILD_TYPES=['Debug', 'RelWithDebInfo', 'Release']
BUILD_TYPE=env.BUILD_TYPE?env.BUILD_TYPE:"Debug"

// Hardware and simulation build modes. 1 is simulation, 0 is hardware
String[] SIMULATION_MODES=[0,1]

EXTRA_CMAKE_ARGS=""

// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"

pipeline {
    options {
        timeout(time: 180, unit: 'MINUTES') 
    }
    agent { label "ACC-RHEL-${LINUX_VERSION}" }

    stages {
        stage('Checkout'){
            steps{
                cleanWs()
                checkout scm
            }
        }
        stage('Build'){
            steps{
                script{
                    def runner = load pwd() + "${SHARED_LIBRARY}"
                    //for(BUILD_TYPE in BUILD_TYPES){
                        stage("RHEL ${LINUX_VERSION} Build - ${BUILD_TYPE}"){
                            try{
                                runner.cleanup()
                                runner.checkout("${PULL_NUMBER}")
                                runner.cmakeBuildopenenclave("${BUILD_TYPE}","${COMPILER}","${EXTRA_CMAKE_ARGS}")
                            } catch (Exception e) {
                                // Do something with the exception 
                                error "Program failed, please read logs..."
                            } finally {
                                runner.cleanup()
                            }
                        }
                    //}
                }
            }
        }
    }
    post ('Clean Up'){
        always{
            cleanWs()
        }
    }
}