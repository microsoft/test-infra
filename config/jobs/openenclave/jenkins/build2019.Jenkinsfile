pipeline {
    agent { label 'SGXFLC-Windows-2019-Docker' }
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }
        stage('Build SGX Win 2019 Docker Image') {
            steps {
                script {
                    echo "build"
                    //docker.build("windows-2019:latest", "-f images/windows/2019/Dockerfile ." )
                }
            }
        }

        stage('Test SGX Win 2019 Docker Image') {
            steps {
                script {
                    docker.image('openenclave/windows-2019:latest').inside('-it --device="class/17eaf82e-e167-4763-b569-5b8273cef6e1"') { c ->
                        bat """
                            git clone --recursive https://github.com/openenclave/openenclave
                            """
                    }
                }
            }
        }
    }
}