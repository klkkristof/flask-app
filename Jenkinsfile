pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  namespace: devops
spec:
  containers:
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args:
    - '\$(JENKINS_SECRET)'
    - '\$(JENKINS_NAME)'
  volumes:
  - name: docker-sock
    emptyDir: {}
"""
        }
    }
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'klkkris/flask-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    echo 'Building Docker image...'
                    sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        
        stage('Push to Docker Hub') {
            steps {
                container('docker') {
                    echo 'Pushing to Docker Hub...'
                    sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    echo 'Deploying to Kubernetes...'
                    sh "kubectl apply -f k8s-deployment.yaml -n devops"
                    sh "kubectl set image deployment/flask-app flask-app=${DOCKER_IMAGE}:${IMAGE_TAG} -n devops"
                    sh "kubectl rollout status deployment/flask-app -n devops --timeout=5m --watch=true"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            container('docker') {
            sh 'docker logout || true'
            }
        }
    }
}
