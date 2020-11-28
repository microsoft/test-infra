// Common openenclave jenkins functions

def cmakeBuildOE( String REPO_NAME, String BUILD_CONFIG, String EXTRA_CMAKE_ARGS, String COMPILER = "" ) {

    if (isUnix()) {
        sh  """
            cd ${REPO_NAME} && \
            mkdir build && cd build &&\
            cmake .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} -Wdev
            ninja -v
            ctest --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
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

// Clean up environment, do not fail on error.
def cleanup( String REPO_NAME) {
    if (isUnix()) {
        try {
                sh  """
                    set +e
                    rm -rf ${REPO_NAME}
                    rm -rf ~/samples
                    sudo rm -rf /opt/openenclave || rm -rf /opt/openenclave
                    """
            } catch (Exception e) {
                // Do something with the exception 
                error "Program failed, please read logs..."
            } 
        
    }
}

def cmakeBuildPackageInstallOE( String REPO_NAME, String BUILD_CONFIG, String EXTRA_CMAKE_ARGS, String COMPILER = "") {
    if (isUnix()) {
        sh  """
            cd ${REPO_NAME} && \
            mkdir build && cd build && \
            cmake .. \
                -G Ninja                                                 \
                -DCMAKE_BUILD_TYPE=RelWithDebInfo                        \
                -DCMAKE_INSTALL_PREFIX:PATH='/opt/openenclave'           \
                -DCPACK_GENERATOR=DEB                                    \
                -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin    \
                ${EXTRA_CMAKE_ARGS}                                      \
                -Wdev
            ninja -v
            ctest --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
            ninja -v package
            sudo ninja -v install
            cp -r /opt/openenclave/share/openenclave/samples ~/
            cd ~/samples
            . /opt/openenclave/share/openenclave/openenclaverc
            for i in *; do
                if [ -d \${i} ]; then
                    cd \${i}
                    mkdir build
                    cd build
                    cmake ..
                    make
                    make run
                    cd ../..
                fi
            done
            """
    }
    else {
        bat """
            cd ${REPO_NAME} && \
            mkdir build && cd build &&\
            vcvars64.bat x64 && \
            cmake.exe ${WORKSPACE}\\${REPO_NAME} -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} -DBUILD_ENCLAVES=ON -DNUGET_PACKAGE_PATH=C:/oe_prereqs -DCPACK_GENERATOR=NuGet ${EXTRA_CMAKE_ARGS} -Wdev && \
            ninja.exe && \
            ctest.exe -V -C ${BUILD_CONFIG} --timeout ${CTEST_TIMEOUT_SECONDS} && \
            cpack.exe -D CPACK_NUGET_COMPONENT_INSTALL=ON -DCPACK_COMPONENTS_ALL=OEHOSTVERIFY && \
            cpack.exe && \
            (if exist C:\\oe rmdir /s/q C:\\oe) && \
            nuget.exe install open-enclave -Source %cd%\\openenclave\\build -OutputDirectory C:\\oe -ExcludeVersion && \
            set CMAKE_PREFIX_PATH=C:\\oe\\open-enclave\\openenclave\\lib\\openenclave\\cmake && \
            cd C:\\oe\\open-enclave\\openenclave\\share\\openenclave\\samples && \
            setlocal enabledelayedexpansion && \
            for /d %%i in (*) do (
                cd C:\\oe\\open-enclave\\openenclave\\share\\openenclave\\samples\\"%%i"
                mkdir build
                cd build
                cmake .. -G Ninja -DNUGET_PACKAGE_PATH=C:\\oe_prereqs -DLVI_MITIGATION=${LVI_MITIGATION} || exit /b %errorlevel%
                ninja || exit /b %errorlevel%
                ninja run || exit /b %errorlevel%
            )
            """
    }
}

// There are a bunch of edgecases, it was easier to have a seperate function for simulation mode.
// WHY WOULD SOMEONE WANT TO BUILD SNMALLOC LVI SIMULATION MODE WHEN BY DESIGN ONLY HALF THE SAMPELS WOULD WORK?!
def cmakeBuildPackageOESim( String REPO_NAME, String BUILD_CONFIG, String EXTRA_CMAKE_ARGS, String COMPILER = "") {
    if (isUnix()) {
        sh  """
            cd ${REPO_NAME} && \
            mkdir build && cd build && \
            cmake .. \
                -G Ninja                                                 \
                -DCMAKE_BUILD_TYPE=RelWithDebInfo                        \
                -DCMAKE_INSTALL_PREFIX:PATH='/opt/openenclave'           \
                -DCPACK_GENERATOR=DEB                                    \
                -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin    \
                ${EXTRA_CMAKE_ARGS}                                      \
                -Wdev
            ninja -v
            ctest --output-on-failure --timeout ${CTEST_TIMEOUT_SECONDS}
            """
    }
    else {
        bat """
            cd ${REPO_NAME} && \
            mkdir build && cd build &&\
            vcvars64.bat x64 && \
            cmake.exe ${WORKSPACE}\\${REPO_NAME} -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} -DBUILD_ENCLAVES=ON -DNUGET_PACKAGE_PATH=C:/oe_prereqs -DCPACK_GENERATOR=NuGet ${EXTRA_CMAKE_ARGS} -Wdev && \
            ninja.exe && \
            ctest.exe -V -C ${BUILD_CONFIG} --timeout ${CTEST_TIMEOUT_SECONDS}
            """
    }
}

def checkout( String REPO_NAME, String OE_PULL_NUMBER) {
    if (isUnix()) {
        sh  """
            git config --global core.compression 0 && \
            rm -rf ${REPO_NAME} && \
            git clone --recursive --depth 1 https://github.com/openenclave-ci/${REPO_NAME} && \
            cd ${REPO_NAME} && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if [[ ${OE_PULL_NUMBER} -ne 'master' ]]; then
                git checkout origin/pr/${OE_PULL_NUMBER}
            fi
            """
    }
    else {
        bat """
            git config --global core.compression 0 && \
            (if exist ${REPO_NAME} rmdir /s/q ${REPO_NAME}) && \
            git clone --recursive --depth 1 https://github.com/openenclave-ci/${REPO_NAME} && \
            cd ${REPO_NAME} && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if NOT ${OE_PULL_NUMBER}==master git checkout origin/pr/${OE_PULL_NUMBER}
            """
    }
}

void cleanContainers() {
    if (isUnix()) {
        sh  """
            docker system prune -f
            """ 
    } else {
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
