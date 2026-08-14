pipeline {
    agent any

    tools {
        jdk 'jdk25'
    }

    environment {
        SCANNER_HOME = tool 'SonarScanner'
    }

    stages {

        stage('Git Checkout') {
            steps {
                git(
                    branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/mova-git/demo.git'
                )
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                          -Dsonar.projectKey=demo \
                          -Dsonar.sources=.
                    '''
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh 'trivy fs .'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t demo:latest .'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image demo:latest'
            }
        }
    }

    post {
        success {
            echo 'Build, SonarQube and Trivy completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}
