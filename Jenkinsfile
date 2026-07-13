pipeline {
    agent any

    tools {
        jdk 'jdk25'              // Match the JDK tool name configured in Jenkins
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
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    withSonarQubeEnv('SonarQube') {
                        bat """
                        "%SCANNER_HOME%\\bin\\sonar-scanner.bat" ^
                        -Dsonar.projectKey=demo ^
                        -Dsonar.sources=. ^
                        -Dsonar.host.url=http://localhost:9000 ^
                        -Dsonar.login=admin ^
                        -Dsonar.password=12345
                        """
                    }
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

    post {
        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}
