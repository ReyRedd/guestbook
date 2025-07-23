pipeline {
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
                        // This command updates your specific deployment.yaml file.
                        // It requires 'yq' to be installed on the Jenkins agent.
                        sh "yq e '.spec.template.spec.containers[0].image = \"${fullImageName}\"' -i apps/guestbook/deployment.yaml"

                        // Configure Git with your user info
                        sh 'git config user.email "mwakioreynold1@gmail.com"'
                        sh 'git config user.name "ReyRedd"'

                        // Add, commit, and push the updated manifest
                        sh 'git add apps/guestbook/deployment.yaml'
                        sh "git commit -m 'ci: Update image for guestbook-app to ${imageTag}'"
                        
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
            // Clean up the cloned cluster-config directory
            deleteDir()
        }
    }
}