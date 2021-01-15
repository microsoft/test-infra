// Common oeedger8r-cpp jenkins function

/** Checkout oeedger8r-cpp, along with merged pull request. If master is instead passed in, don't check out branch
  * as this is being ran as a validation of master or as a reverse integration test on the test-infra repo.
**/

void checkout( String PULL_NUMBER="master" ) {
    if (isUnix()) {
        sh  """
            git config --global core.compression 0 && \
            rm -rf oeedger8r-cpp && \
            git clone --recursive --depth 1 https://github.com/openenclave/oeedger8r-cpp && \
            cd oeedger8r-cpp && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if [ '${PULL_NUMBER}' != 'master' ]
            then
                echo 'checking out  ${PULL_NUMBER}'
                git checkout origin/pr/${PULL_NUMBER}
            fi
            """
    }
    else {
        bat """
            git config --global core.compression 0 && \
            (if exist oeedger8r-cpp rmdir /s/q oeedger8r-cpp) && \
            git clone --recursive --depth 1 https://github.com/openenclave/oeedger8r-cpp && \
            cd oeedger8r-cpp && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if NOT ${PULL_NUMBER}==master git checkout origin/pr/${PULL_NUMBER}
            """
    }
}

/** Build oeedgr8r based on build config, compiler and platform
  * TODO: Add container support
**/
def cmakeBuildoeedger8r( String BUILD_CONFIG="Release", String COMPILER="clang-7" ) {
    dir ('oeedger8r-cpp/build') {
        if (isUnix()) {

            sh  """
                echo COMPILER IS ${COMPILER}
                """
            def c_compiler
            def cpp_compiler
            def compiler_version
            switch(COMPILER) {
                case "clang-8":
                    c_compiler = "clang"
                    cpp_compiler = "clang++"
                    compiler_version = "8"
                    break
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
                sh  """
                    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} -Wdev
                    ninja -v
                    ctest --output-on-failure --timeout
                    """
            }
        } else {
            bat """
                vcvars64.bat x64 && \
                cmake.exe .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} && \
                ninja -v -j 4 && \
                ctest.exe -V --output-on-failure
                """
        }
    }
}

// Clean up environment, do not fail on error.
def cleanup() {
    if (isUnix()) {
        try {
                sh  """
                    sudo rm -rf oeedger8r-cpp || rm -rf oeedger8r-cpp || echo 'Workspace is clean'
                    """
            } catch (Exception e) {
                // Do something with the exception 
                error "Program failed, please read logs..."
            } 
        
    }
}

return this
