pipeline {
    agent any
    options {
        timeout(time: 30, unit: 'MINUTES') 
    }
    parameters {
        string(
            name: "LVI_MITIGATION",
            defaultValue: "ControlFlow",
            description: ""
        )
        choice(
            name: "LVI_MITIGATION_SKIP_TESTS",
            choices: ['OFF', 'ON'],
            description: "Skip LVI migitation tests?"
        )
        string(
            name: "BUILD_TYPE",
            defaultValue: "Debug",
            description: ""
        )
        string(
            name: "DOCKER_VERSION",
            defaultValue: "latest",
            description: "Version of Docker to build with"
        )
        string(
            name: "EXTRA_CMAKE_ARGS",
            defaultValue: "",
            description: "Extra arguments to pass to cmake"
        )
    }
    environment {
        GLOBAL_TIMEOUT_MINUTES = 120
        CTEST_TIMEOUT_SECONDS = 1200
    }
    stages {
        stage( 'Ubuntu 1804 Build') {
            agent { label "ACC-Ubuntu-1804" }
            steps {
                cleanWs()
                checkout scm
                script {
                    def rootDir = pwd()
                    def runner = load "${rootDir}/config/jobs/openenclave/jenkins/common.groovy"
                    runner.cmakeBuildPackageInstallOE("${REPO}","${BUILD_TYPE}", "${EXTRA_CMAKE_ARGS}")
                }
            }
        }
    }
}
