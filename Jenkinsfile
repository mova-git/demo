pipeline {
    agent any

    tools {
         jdk 'jdk25'
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                url: 'https://github.com/mova-git/demo.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    bat '''
                    sonar-scanner \
                    -Dsonar.projectKey=nodeapp \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=http://43.204.19.250:9000 \
                    -Dsonar.login=TOKEN
                    '''
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                bat 'trivy fs .'
            }
        }

        stage('Docker Build') {
            steps {
                bat 'docker build -t node-app .'
            }
        }

        stage('Docker Image Scan') {
            steps {
                bat 'trivy image node-app'
            }
        }
    }
}
