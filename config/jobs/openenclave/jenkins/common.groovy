// Common openenclave jenkins functions

/** Checkout openenclave, along with merged pull request. If master is instead passed in, don't check out branch
  * as this is being ran as a validation of master or as a reverse integration test on the test-infra repo.
**/

void checkout( String PULL_NUMBER="master" ) {
    if (isUnix()) {
        sh  """
            git config --global core.compression 0 && \
            rm -rf openenclave && \
            git clone --recursive --depth 1 https://github.com/openenclave/openenclave && \
            cd openenclave && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if [[ ${PULL_NUMBER} -ne 'master' ]]; then
                git checkout origin/pr/${PULL_NUMBER}
            fi
            """
    }
    else {
        bat """
            git config --global core.compression 0 && \
            (if exist openenclave rmdir /s/q openenclave) && \
            git clone --recursive --depth 1 https://github.com/openenclave/openenclave && \
            cd openenclave && \
            git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
            if NOT ${PULL_NUMBER}==master git checkout origin/pr/${PULL_NUMBER}
            """
    }
}

/* installOpenEnclavePrereqs
*  Runs ansible configuration on vanilla vm to allow e2e variant
*/
void installOpenEnclavePrereqs() {
    dir ('openenclave') {
        if (isUnix()) {
            sh  """
                sudo bash scripts/ansible/install-ansible.sh
                # Run ACC Playbook
                for i in 1 2 3 4 5
                do
                    sudo \$(which ansible-playbook) scripts/ansible/oe-contributors-acc-setup.yml && break
                    sleep 60
                done
                """
        }
        else {
            // Not implemented yes
            bat """
                """
        }
    }
}

def AArch64GNUTest(String BUILD_TYPE) {
    dir ('openenclave/build') {
        def task = """
                    cmake ..                                                               \
                        -G Ninja                                                           \
                        -DCMAKE_BUILD_TYPE=${BUILD_TYPE}                                   \
                        -DCMAKE_TOOLCHAIN_FILE=../cmake/arm-cross.cmake                    \
                        -DOE_TA_DEV_KIT_DIR=/devkits/vexpress-qemu_armv8a/export-ta_arm64  \
                        -DHAS_QUOTE_PROVIDER=OFF                                           \
                        -Wdev
                    ninja -v
                    """
        ContainerRun("oeciteam/oetools-full-18.04", "cross", task, "--cap-add=SYS_PTRACE")
    }
}

/** Build openenclave based on build config, compiler and platform
  * TODO: Add container support
**/
def cmakeBuildopenenclave( String BUILD_CONFIG="Release", String COMPILER="clang-7", String EXTRA_CMAKE_ARGS ="") {
    dir ('openenclave/build') {
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
                    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} ${EXTRA_CMAKE_ARGS} -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin -DCMAKE_INSTALL_PREFIX:PATH='/opt/openenclave' -DCPACK_GENERATOR=DEB -Wdev
                    ninja -v
                    ctest --output-on-failure --timeout
                    """
            }
        } else {
            bat """
                vcvars64.bat x64 && \
                cmake.exe .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} -DBUILD_ENCLAVES=ON -DNUGET_PACKAGE_PATH=C:/oe_prereqs -DCPACK_GENERATOR=NuGet ${EXTRA_CMAKE_ARGS} -Wdev && \
                ninja.exe && \
                ctest.exe -V -C ${BUILD_CONFIG} --output-on-failure
                """
        }
    }
}

// Common build and package functionality. WIP

def openenclavepackageInstall( String BUILD_CONFIG="Release", String COMPILER="clang-7", String EXTRA_CMAKE_ARGS ="") {
    dir ('openenclave/build') {
        // Duplicate code here, refactor out once package is complete
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
            // To do, switch ninja to cpack sometimes?

            withEnv(["CC=${c_compiler}","CXX=${cpp_compiler}"]) {
                sh  """
                    sudo ninja -v package
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
        } else {
            //Missing lvi sample test case
            bat """
                vcvars64.bat x64 && \
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
                    cmake .. -G Ninja -DNUGET_PACKAGE_PATH=C:\\oe_prereqs -DLVI_MITIGATION=OFF || exit /b %errorlevel%
                    ninja || exit /b %errorlevel%
                    ninja run || exit /b %errorlevel%
                )
                """
        }
    }
}

// Clean up environment, do not fail on error.
def cleanup() {
    if (isUnix()) {
        try {
                sh  """
                    sudo rm -rf openenclave || rm -rf openenclave || echo 'Workspace is clean'
                    sudo rm -rf /opt/openenclave || rm -rf /opt/openenclave || echo 'Workspace is clean'
                    sudo rm -rf ~/samples || rm -rf ~/samples || echo 'Workspace is clean'
                    """
            } catch (Exception e) {
                // Do something with the exception 
                error "Program failed, please read logs..."
            } 
        
    }
}

/// This is copy and pasted from the deprecated openenclave-ci repo and is used for multiphase tests, we should consider cleaning this up and refactoring 
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