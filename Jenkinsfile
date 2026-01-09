pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'klkkris/flask-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out Python Flask source code...'
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image for Flask app...'
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Test Image') {
            steps {
                echo 'Testing Docker image...'
                script {
                    sh """
                        docker run -d --name test-flask -p 5001:5000 ${DOCKER_IMAGE}:${IMAGE_TAG}
                        sleep 5
                        curl -f http://localhost:5001/ || exit 1
                        curl -f http://localhost:5001/health || exit 1
                        docker stop test-flask
                        docker rm test-flask
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing Flask image to Docker Hub...'
                script {
                    sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying Flask app to Kubernetes...'
                script {
                    sh "kubectl apply -f k8s-deployment.yaml"
                    sh "kubectl apply -f k8s-service.yaml"
                    sh "kubectl rollout restart deployment/flask-app"
                    sh "kubectl rollout status deployment/flask-app --timeout=2m"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Flask Pipeline completed successfully!'
        }
        failure {
            echo 'Flask Pipeline failed!'
        }
        always {
            sh 'docker logout || true'
            sh 'docker rm -f test-flask || true'
        }
    }
}
