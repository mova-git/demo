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
        ECS_TASK_DEFINITION = 'myapp-task'
        ECS_CONTAINER_NAME = 'myapp-container'

        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_NAME = "025066283875.dkr.ecr.ap-south-1.amazonaws.com/myapp-repository:${BUILD_NUMBER}"

        SCANNER_HOME = tool 'SonarScanner'
    }

    stages {

        stage('Check Tools') {
            steps {
                sh '''
                    echo "Checking required tools..."

                    java -version
                    docker --version
                    aws --version
                    trivy --version
                    jq --version

                    echo "SonarScanner:"
                    ${SCANNER_HOME}/bin/sonar-scanner --version
                '''
            }
        }

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        ${SCANNER_HOME}/bin/sonar-scanner \
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
                    trivy fs \
                      --scanners vuln \
                      --severity HIGH,CRITICAL \
                      --exit-code 0 \
                      .
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build \
                      -t ${ECR_REPOSITORY}:${IMAGE_TAG} \
                      .
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    echo "Scanning Docker image with Trivy..."
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --exit-code 0 \
                      ${ECR_REPOSITORY}:${IMAGE_TAG}
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

        stage('Create ECS Task Definition') {
            steps {
                sh '''
                    echo "Creating new ECS task definition..."

                    aws ecs describe-task-definition \
                      --task-definition ${ECS_TASK_DEFINITION} \
                      --region ${AWS_REGION} \
                      --query taskDefinition \
                      --output json > task-definition.json

                    jq \
                      --arg IMAGE "${IMAGE_NAME}" \
                      --arg CONTAINER "${ECS_CONTAINER_NAME}" \
                      '
                      .containerDefinitions |=
                        map(
                          if .name == $CONTAINER
                          then .image = $IMAGE
                          else .
                          end
                        )
                      |
                      del(
                        .taskDefinitionArn,
                        .revision,
                        .status,
                        .requiresAttributes,
                        .compatibilities,
                        .registeredAt,
                        .registeredBy,
                        .tags
                      )
                      ' task-definition.json > new-task-definition.json

                    echo "New image:"
                    jq -r \
                      '.containerDefinitions[] | select(.name == "'${ECS_CONTAINER_NAME}'") | .image' \
                      new-task-definition.json

                    aws ecs register-task-definition \
                      --cli-input-json file://new-task-definition.json \
                      --region ${AWS_REGION}
                '''
            }
        }

        stage('Deploy to ECS') {
            steps {
                sh '''
                    NEW_REVISION=$(aws ecs describe-task-definition \
                      --task-definition ${ECS_TASK_DEFINITION} \
                      --region ${AWS_REGION} \
                      --query 'taskDefinition.revision' \
                      --output text)

                    echo "Deploying task definition revision: ${NEW_REVISION}"

                    aws ecs update-service \
                      --cluster ${ECS_CLUSTER} \
                      --service ${ECS_SERVICE} \
                      --task-definition ${ECS_TASK_DEFINITION}:${NEW_REVISION} \
                      --region ${AWS_REGION}
                '''
            }
        }

        stage('Wait for ECS') {
            steps {
                sh '''
                    echo "Waiting for ECS service to become stable..."

                    aws ecs wait services-stable \
                      --cluster ${ECS_CLUSTER} \
                      --services ${ECS_SERVICE} \
                      --region ${AWS_REGION}

                    echo "ECS deployment completed successfully."
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "Current ECS task definition:"

                    aws ecs describe-services \
                      --cluster ${ECS_CLUSTER} \
                      --services ${ECS_SERVICE} \
                      --region ${AWS_REGION} \
                      --query 'services[0].[serviceName,taskDefinition,runningCount,desiredCount]' \
                      --output table
                '''
            }
        }
    }

    post {
        success {
            echo 'Application successfully deployed to ECS!'
            echo "Docker Image: ${IMAGE_NAME}"
        }

        failure {
            echo 'Pipeline failed. Check Console Output.'
        }

        always {
            sh '''
                rm -f task-definition.json
                rm -f new-task-definition.json
            '''
        }
    }
}
