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
                    docker.build("windows-2019:latest", "-f images/windows/2019/Dockerfile ." )
                }
            }
        }

        stage('Test SGX Win 2019 Docker Image') {
            steps {
                def image = docker.image('openenclave/windows-2019')
                image.pull()
            }
        }
    }
}