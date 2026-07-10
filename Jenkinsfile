pipeline {
    agent any

    tools {
        sonarQube 'SonarScanner'
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
                    sh '''
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
                sh 'trivy fs .'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t node-app .'
            }
        }

        stage('Docker Image Scan') {
            steps {
                sh 'trivy image node-app'
            }
        }
    }
}
