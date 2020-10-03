CTEST_TIMEOUT_SECONDS = 480
PULL_NUMBER = env.PULL_NUMBER
TEST_INFRA = env.TEST_INFRA
TEST_INFRA ? PULL_NUMBER='master' : null

pipeline {
    agent { label 'SGXFLC-Windows-2019-Docker' }
    stages {
        stage('Win 2019 Build Release') {
            steps {
                script {
                    docker.image('openenclave/windows-2019:0.1').inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                        checkout_windows("openenclave","oeedger8r-cpp")
                        cmake_build_windows("oeedger8r-cpp","Release")
                    }
                }
            }
        }
        stage('Win 2019 Build Debug') {
            steps {
                script {
                    docker.image('openenclave/windows-2019:0.1').inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                        checkout_windows("openenclave","oeedger8r-cpp")
                        cmake_build_windows("oeedger8r-cpp","Debug")
                    }
                }
            }
        }
    }
}

void checkout_windows(String REPO_OWNER, String REPO_NAME ) {
    bat """
        (if exist ${REPO_NAME} rmdir /s/q ${REPO_NAME}) && \
        git clone https://github.com/${REPO_OWNER}/${REPO_NAME} && \
        cd ${REPO_NAME} && \
        git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
        if NOT ${PULL_NUMBER}==master git checkout_windows origin/pr/${PULL_NUMBER}
        """
}

void cmake_build_windows( String REPO_NAME, String BUILD_CONFIG ) {
    bat """
        cd ${REPO_NAME} && \
        mkdir build && cd build &&\
        vcvars64.bat x64 && \
        cmake.exe .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} && \
        ninja -v -j 4 && \
        ctest.exe -V --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
        """
}
