// Timeout configs
GLOBAL_TIMEOUT_MINUTES = 120
CTEST_TIMEOUT_SECONDS = 1200

// Pull Request Information
OE_PULL_NUMBER=env.OE_PULL_NUMBER?env.OE_PULL_NUMBER:"master"

// OS Version Configuration
WINDOWS_VERSION=env.WINDOWS_VERSION?env.WINDOWS_VERSION:"2019"

// Some Defaults
DOCKER_TAG=env.DOCKER_TAG?env.DOCKER_TAG:"latest"
BUILD_TYPE=env.BUILD_TYPE?env.BUILD_TYPE:"Release"
BUILD_MODE=env.BUILD_MODE?env.BUILD_MODE:"hardware"

// Some override for build configuration
EXTRA_CMAKE_ARGS=env.EXTRA_CMAKE_ARGS?env.EXTRA_CMAKE_ARGS:"-DLVI_MITIGATION=ControlFlow -DLVI_MITIGATION_SKIP_TESTS=OFF -DUSE_SNMALLOC=ON"

// LVI_mitigation
LVI_MITIGATION = env.LVI_MITIGATION?env.LVI_MITIGATION:"ControlFlow"
LVI_MITIGATION_SKIP_TESTS = env.LVI_MITIGATION_SKIP_TESTS?env.LVI_MITIGATION_SKIP_TESTS:"OFF"

// Shared library config, check out common.groovy!
SHARED_LIBRARY="/config/jobs/openenclave/jenkins/common.groovy"

pipeline {
    options {
        timeout(time: 60, unit: 'MINUTES') 
    }
    agent { label "SGXFLC-Windows-${WINDOWS_VERSION}-Docker" }
    stages {
        stage( 'Windows Build') {
            steps {
                //withEnv(["OE_SIMULATION=1"]) {
                    script {
                        //docker.image("openenclave/windows-${WINDOWS_VERSION}:${DOCKER_TAG}").inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                            cleanWs()
                            checkout scm
                            def runner = load pwd() + "${SHARED_LIBRARY}"
                            runner.checkout("${OE_PULL_NUMBER}")
                            runner.cmakeBuildPackageInstallOE("${REPO}","${BUILD_TYPE}", "${EXTRA_CMAKE_ARGS}")
                        //}
                    }
                //}
            }
        }
    }
}
