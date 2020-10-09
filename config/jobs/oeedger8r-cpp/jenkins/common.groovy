// Common oeedger8r-cpp jenkins functions
def cmakeBuild( String REPO_NAME, String BUILD_CONFIG ) {

    if (isUnix()) {
        sh  """
            cd ${REPO_NAME} && \
            mkdir build && cd build &&\
            cmake .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} -Wdev
            ninja -v
            ctest --output-on-failure --timeout ${REPO_NAME}
            """
    } else {
        bat """
            cd ${REPO_NAME} && \
            mkdir build && cd build &&\
            vcvars64.bat x64 && \
            cmake.exe .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} && \
            ninja -v -j 4 && \
            ctest.exe -V --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
            """
    }
}

def checkout( String REPO_NAME ) {
    if (isUnix()) {
        sh  """
            export GIT_TRACE_PACKET=1
            export GIT_TRACE=1
            export GIT_CURL_VERBOSE=1
            rm -rf ${REPO_NAME} && \
            git clone --recursive --depth 1 https://github.com/openenclave/${REPO_NAME} && \
            cd ${REPO_NAME} && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if [[ $PULL_NUMBER -ne 'master' ]]; then
                git checkout origin/pr/${PULL_NUMBER}
            fi
            """
    }
    else {
        bat """
            set GIT_TRACE_PACKET=1
            set GIT_TRACE=1
            set GIT_CURL_VERBOSE=1
            (if exist ${REPO_NAME} rmdir /s/q ${REPO_NAME}) && \
            git clone --recursive --depth 1 https://github.com/openenclave/${REPO_NAME} && \
            cd ${REPO_NAME} && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if NOT ${PULL_NUMBER}==master git checkout origin/pr/${PULL_NUMBER}
            """
    }
}

def containerClean() {
    if (isUnix()) {
        sh  """
            docker system prune -f
            """
    }
    else {
        bat """
            docker system prune -f
            """
    }
}

def ContainerRun(String imageName, String compiler, String task, String runArgs="") {
    def image = docker.image(imageName)
    image.pull()
    image.inside(runArgs) {
        dir("${WORKSPACE}/openenclave/build") {
            Run(compiler, task)
        }
    }
}

def runTask(String task) {
    dir("${WORKSPACE}/build") {
        sh """#!/usr/bin/env bash
                set -o errexit
                set -o pipefail
                source /etc/profile
                ${task}
            """
    }
}

def Run(String compiler, String task, String compiler_version = "") {
    def c_compiler
    def cpp_compiler
    switch(compiler) {
        case "cross":
            // In this case, the compiler is set by the CMake toolchain file. As
            // such, it is not necessary to specify anything in the environment.
            runTask(task)
            return
        case "clang-7":
            c_compiler = "clang"
            cpp_compiler = "clang++"
            compiler_version = "7"
            break
        case "gcc":
            c_compiler = "gcc"
            cpp_compiler = "g++"
            break
        default:
            // This is needed for backwards compatibility with the old
            // implementation of the method.
            c_compiler = "clang"
            cpp_compiler = "clang++"
            compiler_version = "8"
    }
    if (compiler_version) {
        c_compiler += "-${compiler_version}"
        cpp_compiler += "-${compiler_version}"
    }
    withEnv(["CC=${c_compiler}","CXX=${cpp_compiler}"]) {
        runTask(task);
    }
}

return this
