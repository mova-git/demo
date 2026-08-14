pipeline {
    agent any

    tools {
        jdk 'jdk21'
    }

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '025066283875'

        ECR_REPOSITORY = 'myapp-repository'
        ECR_REGISTRY = '025066283875.dkr.ecr.ap-south-1.amazonaws.com'

        ECS_CLUSTER = 'myapp-cluster'
        ECS_SERVICE = 'myapp-service'

        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_NAME = "025066283875.dkr.ecr.ap-south-1.amazonaws.com/myapp-repository:${BUILD_NUMBER}"
    }

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=demo \
                          -Dsonar.projectName=demo \
                          -Dsonar.sources=.
                    '''
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    trivy fs --scanners vuln .
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    trivy image ${ECR_REPOSITORY}:${IMAGE_TAG}
                '''
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    aws ecr get-login-password \
                    --region ${AWS_REGION} | \
                    docker login \
                    --username AWS \
                    --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Docker Tag') {
            steps {
                sh '''
                    docker tag \
                    ${ECR_REPOSITORY}:${IMAGE_TAG} \
                    ${IMAGE_NAME}
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh '''
                    docker push ${IMAGE_NAME}
                '''
            }
        }

        stage('Deploy to ECS') {
            steps {
                sh '''
                    aws ecs update-service \
                    --cluster ${ECS_CLUSTER} \
                    --service ${ECS_SERVICE} \
                    --force-new-deployment \
                    --region ${AWS_REGION}
                '''
            }
        }

        stage('Wait for ECS') {
            steps {
                sh '''
                    aws ecs wait services-stable \
                    --cluster ${ECS_CLUSTER} \
                    --services ${ECS_SERVICE} \
                    --region ${AWS_REGION}
                '''
            }
        }
    }

    post {
        success {
            echo 'Application successfully deployed to ECS!'
        }

        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}
