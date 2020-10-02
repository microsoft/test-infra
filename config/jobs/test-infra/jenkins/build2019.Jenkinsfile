CTEST_TIMEOUT_SECONDS = 480
PULL_NUMBER = env.PULL_NUMBER
TEST_INFRA = env.TEST_INFRA
TEST_INFRA ? PULL_NUMBER = "master" : null

pipeline {
    agent { label 'SGXFLC-Windows-2019-Docker' }
    stages {
        stage('Build SGX Win 2019 Docker Image') {
            steps {
                script {
                    checkout("openenclave-ci","test-infra")
                    docker.build("windows-2019:latest", "-f images/windows/2019/Dockerfile ." )
                }
            }
        }

        stage('Test SGX Win 2019 Docker Image - Release') {
            steps {
                script {
                    docker.image('openenclave/windows-2019:latest').inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                        bat """
                            (if exist openenclave rmdir /s/q openenclave) && \
                            git clone --recursive https://github.com/openenclave/openenclave && \
                            cd openenclave && \
                            mkdir build && cd build && \
                            vcvars64.bat && cmake .. -G Ninja -DNUGET_PACKAGE_PATH=C:\\Downloads\\prereqs\\nuget -DCPACK_GENERATOR=NuGet -DCMAKE_BUILD_TYPE=Release -DBUILD_ENCLAVES=ON -DLVI_MITIGATION=None -DHAS_QUOTE_PROVIDER=ON && \
                            ninja -j 1 -v && \
                            ctest.exe -V -C Release --timeout 480 && \
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
                                cmake .. -G Ninja -DNUGET_PACKAGE_PATH=C:\\oe_prereqs -DLVI_MITIGATION=None || exit /b %errorlevel%
                                ninja || exit /b %errorlevel%
                                ninja run || exit /b %errorlevel%
                            )
                            """
                    }
                }
            }
        }

        stage('Test SGX Win 2019 Docker Image - Debug') {
            steps {
                script {
                    docker.image('openenclave/windows-2019:latest').inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                        bat """
                            (if exist openenclave rmdir /s/q openenclave) && \
                            git clone --recursive https://github.com/openenclave/openenclave && \
                            cd openenclave && \
                            mkdir build && cd build && \
                            vcvars64.bat && cmake .. -G Ninja -DNUGET_PACKAGE_PATH=C:\\Downloads\\prereqs\\nuget -DCPACK_GENERATOR=NuGet -DCMAKE_BUILD_TYPE=Debug -DBUILD_ENCLAVES=ON -DLVI_MITIGATION=None -DHAS_QUOTE_PROVIDER=ON && \
                            ninja -j 1 -v && \
                            ctest.exe -V -C Debug --timeout 480 && \
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
                                cmake .. -G Ninja -DNUGET_PACKAGE_PATH=C:\\oe_prereqs -DLVI_MITIGATION=None || exit /b %errorlevel%
                                ninja || exit /b %errorlevel%
                                ninja run || exit /b %errorlevel%
                            )
                            """
                    }
                }
            }
        }
    }
}

void checkout(String REPO_OWNER, String REPO_NAME ) {
    bat """
        (if exist ${REPO_NAME} rmdir /s/q ${REPO_NAME}) && \
        git clone https://github.com/${REPO_OWNER}/${REPO_NAME} && \
        cd ${REPO_NAME} && \
        git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/*
        if NOT ${PULL_NUMBER}==master git checkout origin/pr/${PULL_NUMBER}
        """
}
