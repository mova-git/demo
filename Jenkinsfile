pipeline {
    agent any

    tools {
        jdk 'jdk21'              // Change this to your JDK name in Jenkins
    }

    environment {
        SCANNER_HOME = tool 'SonarScanner'   // Name configured in Manage Jenkins → Tools
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'mova-git',
                    url: 'https://github.com/mova-git/demo.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    bat """
                    "%SCANNER_HOME%\\bin\\sonar-scanner.bat" ^
                    -Dsonar.projectKey=squ_308be2f9f5474bc840f2f512e0ab393d2eba0b68 ^
                    -Dsonar.sources=. ^
                    -Dsonar.host.url=http://localhost:9000
                    """
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
                bat 'docker build -t demo .'
            }
        }

        stage('Docker Image Scan') {
            steps {
                bat 'trivy image demo'
            }
        }
    }
}

        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}