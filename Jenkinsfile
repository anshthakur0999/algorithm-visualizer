pipeline {
    agent any
    
    environment {
        // Docker Hub credentials (configure in Jenkins)
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE = 'anshthakur503/algorithm-visualizer'  // Replace with your Docker Hub username
        KUBECONFIG_CREDENTIALS = credentials('kubeconfig')
        AWS_CREDENTIALS = credentials('aws-credentials')
        
        // Build information
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = "${env.GIT_COMMIT[0..7]}"
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Checking out source code..."
                    checkout scm
                    
                    // Set additional environment variables
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Validate') {
            parallel {
                stage('Lint HTML/CSS/JS') {
                    steps {
                        script {
                            echo "🔍 Validating code quality..."
                            
                            // Basic validation for HTML
                            sh '''
                                echo "Checking HTML syntax..."
                                if command -v tidy >/dev/null 2>&1; then
                                    tidy -q -e index.html || echo "HTML validation completed with warnings"
                                else
                                    echo "HTML Tidy not available, skipping HTML validation"
                                fi
                            '''
                            
                            // Check for JavaScript syntax errors
                            sh '''
                                echo "Checking JavaScript syntax..."
                                if command -v node >/dev/null 2>&1; then
                                    node -c app.js || exit 1
                                    echo "JavaScript syntax check passed"
                                else
                                    echo "Node.js not available, skipping JavaScript validation"
                                fi
                            '''
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        script {
                            echo "🔒 Running security checks..."
                            
                            // Basic security checks
                            sh '''
                                echo "Checking for sensitive data..."
                                if grep -r "password\\|secret\\|key" --include="*.js" --include="*.html" --include="*.css" . | grep -v "// " | grep -v "/*"; then
                                    echo "⚠️  Potential sensitive data found in code"
                                else
                                    echo "✅ No obvious sensitive data found"
                                fi
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    
                    // Build the Docker image
                    def image = docker.build("${DOCKER_IMAGE}:${IMAGE_TAG}")
                    
                    // Tag as latest
                    sh "docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest"
                    
                    echo "✅ Docker image built successfully: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo "🧪 Testing Docker image..."
                    
                    // Run container for testing
                    sh '''
                        # Start container in background
                        docker run -d --name test-container -p 8081:8080 ${DOCKER_IMAGE}:${IMAGE_TAG}
                        
                        # Wait for container to start
                        sleep 10
                        
                        # Check if container is running
                        if ! docker ps | grep test-container; then
                            echo "❌ Container failed to start"
                            docker logs test-container
                            exit 1
                        fi
                        
                        # Test main page (remove health check since it doesn't exist)
                        if curl -f http://localhost:8081/ | grep -q "Algorithm\\|Visualizer\\|html"; then
                            echo "✅ Main page test passed"
                        else
                            echo "❌ Main page test failed"
                            echo "Response:"
                            curl -v http://localhost:8081/ || true
                            docker logs test-container
                            exit 1
                        fi
                        
                        # Cleanup
                        docker stop test-container
                        docker rm test-container
                    '''
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    echo "📤 Pushing Docker image to registry..."
                    
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        sh "docker push ${DOCKER_IMAGE}:${IMAGE_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                    
                    echo "✅ Docker image pushed successfully"
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "🚀 Deploying to Kubernetes..."
                    
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh '''
                            # Update image in deployment
                            sed -i "s|image: .*|image: ${DOCKER_IMAGE}:${IMAGE_TAG}|g" k8s/deployment.yaml
                            
                            # Apply Kubernetes manifests
                            kubectl apply -f k8s/namespace.yaml
                            kubectl apply -f k8s/deployment.yaml
                            kubectl apply -f k8s/service.yaml
                            kubectl apply -f k8s/ingress.yaml
                            kubectl apply -f k8s/hpa.yaml
                            
                            # Wait for rollout to complete
                            kubectl rollout status deployment/algorithm-visualizer -n algorithm-visualizer --timeout=600s
                            
                            # Verify deployment
                            kubectl get pods -n algorithm-visualizer
                        '''
                    }
                    
                    echo "✅ Deployment completed successfully"
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Cleanup Docker images
                sh '''
                    docker image prune -f
                    docker system prune -f --volumes
                '''
            }
        }
        
        success {
            script {
                echo "🎉 Pipeline completed successfully!"
                
                // Send success notification (configure webhook URL)
                // sh '''
                //     curl -X POST -H 'Content-type: application/json' \
                //     --data '{"text":"✅ Algorithm Visualizer deployment successful! Build: ${BUILD_NUMBER}"}' \
                //     YOUR_SLACK_WEBHOOK_URL
                // '''
            }
        }
        
        failure {
            script {
                echo "❌ Pipeline failed!"
                
                // Send failure notification
                // sh '''
                //     curl -X POST -H 'Content-type: application/json' \
                //     --data '{"text":"❌ Algorithm Visualizer deployment failed! Build: ${BUILD_NUMBER}"}' \
                //     YOUR_SLACK_WEBHOOK_URL
                // '''
            }
        }
        
        cleanup {
            // Clean workspace
            cleanWs()
        }
    }
}






