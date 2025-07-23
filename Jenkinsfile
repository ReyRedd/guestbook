pipeline {
    // Use any agent for now until Docker is installed
    agent any
    
    environment {
        // For Docker Hub, the "registry" is your username
        DOCKER_REGISTRY = 'reyredd'
        DOCKER_IMAGE_NAME = 'guestbook'
        
        // Your Jenkins credentials ID for Docker Hub
        DOCKER_CREDENTIALS_ID = 'dockerhub-creds'
        
        // Your GitOps repository URL and credentials ID
        GITOPS_REPO_URL = "https://github.com/ReyRedd/cluster-config.git"
        GITOPS_REPO_CREDS_ID = 'gitops-repo-creds'
    }

    stages {
        stage('System Check') {
            steps {
                sh '''
                    echo "=== System Information ==="
                    whoami
                    pwd
                    
                    echo "=== Available Commands ==="
                    which docker || echo "❌ Docker not found - needs to be installed"
                    which git || echo "❌ Git not found"
                    which yq || echo "❌ yq not found - will use sed"
                    which sed || echo "✅ sed found"
                    
                    echo "=== Docker Check ==="
                    if command -v docker > /dev/null 2>&1; then
                        docker --version
                        docker ps || echo "Docker daemon not running or permission denied"
                    else
                        echo "Docker is not installed on this system"
                    fi
                '''
            }
        }
        
        stage('Checkout SCM') {
            steps {
                // This cleans the workspace before checking out the application code
                cleanWs()
                checkout scm
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Check if Docker is available
                    def dockerAvailable = sh(script: 'which docker', returnStatus: true) == 0
                    
                    if (!dockerAvailable) {
                        error "Docker is not installed on this Jenkins agent. Please install Docker first."
                    }
                    
                    // Use the short git commit hash for the image tag
                    def imageTag = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    def fullImageName = "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${imageTag}"

                    // Use credentials to log in, build, and push the image
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "docker build -t ${fullImageName} ."
                        // For Docker Hub, the login command does not need the registry URL
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                        sh "docker push ${fullImageName}"
                    }
                }
            }
        }

        stage('Update, Commit, and Push Manifest') {
            steps {
                script {
                    def imageTag = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    def fullImageName = "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${imageTag}"

                    // Clone the separate GitOps configuration repository
                    withCredentials([usernamePassword(credentialsId: GITOPS_REPO_CREDS_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh """
                            git clone https://${GIT_USER}:${GIT_PASS}@github.com/ReyRedd/cluster-config.git cluster-config
                        """
                    }
                    
                    // Work inside the cloned repository
                    dir('cluster-config') {
                        // Check if yq is available, otherwise use sed
                        def yqAvailable = sh(script: 'which yq', returnStatus: true) == 0
                        
                        if (yqAvailable) {
                            echo "Using yq to update deployment.yaml"
                            sh "yq e '.spec.template.spec.containers[0].image = \"${fullImageName}\"' -i apps/guestbook/deployment.yaml"
                        } else {
                            echo "Using sed to update deployment.yaml (yq not available)"
                            sh "sed -i 's|image: .*|image: ${fullImageName}|g' apps/guestbook/deployment.yaml"
                        }

                        // Configure Git with your user info
                        sh 'git config user.email "mwakioreynold1@gmail.com"'
                        sh 'git config user.name "ReyRedd"'

                        // Add, commit, and push the updated manifest
                        sh 'git add apps/guestbook/deployment.yaml'
                        sh "git commit -m 'ci: Update image for guestbook-app to ${imageTag}'"
                        
                        // FIXED: Removed duplicate username in the push URL
                        withCredentials([usernamePassword(credentialsId: GITOPS_REPO_CREDS_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                            sh "git push https://${GIT_USER}:${GIT_PASS}@github.com/ReyRedd/cluster-config.git main"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Only clean up if we're in a node context
                try {
                    deleteDir()
                } catch (Exception e) {
                    echo "Could not clean workspace: ${e.getMessage()}"
                }
            }
        }
    }
}