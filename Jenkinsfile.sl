@Library('my-shared-library') _

pipeline {
    environment {
        sonar_token = credentials('SONAR_TOKEN_ID')
    }

    agent any
    tools {
        maven 'Maven 3.9.5'
        jdk 'jdk8'
    }

    parameters {
        string(name: 'ProjectKey', defaultValue: 'shared-lib', description: 'SonarQube project key')
        string(name: 'ProjectName', defaultValue: 'shared-lib', description: 'SonarQube project name')
        string(name: 'SonarHostUrl', defaultValue: 'http://localhost:9000', description: 'SonarQube server URL')
        string(name: 'GIT_REPO', defaultValue: 'https://github.com/cloudsheger/spring-petclinic-jenkins-pipeline-project.git', description: 'GitHub repo')
        string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'GitHub branch name')

        // Artifactory related variables
        string(name: 'DOCKER_REGISTRY', defaultValue: 'cloudsheger.jfrog.io', description: 'Artifactory Docker registry URL')
        string(name: 'DOCKER_REPO', defaultValue: 'docker', description: 'Artifactory Docker repository name')
        string(name: 'IMAGE_NAME', defaultValue: 'petclinic', description: 'Docker image name')
        string(name: 'BUILD_NUMBER', defaultValue: env.BUILD_NUMBER, description: 'Build number')
        string(name: 'ARTIFACTORY_CREDENTIALS_ID', defaultValue: 'artifactory-credentials', description: 'Artifactory credentials ID')
    }

    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout SCM') {
            steps {
                git branch: params.GIT_BRANCH, url: params.GIT_REPO
            }
        }

        stage('Compile') {
            steps {
                sh 'mvn compile'
            }
        }

        stage('Test & Build') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Sonar Static Code Analysis') {
            steps {
                withCredentials([string(credentialsId: 'SONAR_TOKEN_ID', variable: 'sonar_token')]) {
                    sonarScanPipeline(
                        projectKey: params.ProjectKey,
                        projectName: params.ProjectName,
                        sonarHostUrl: params.SonarHostUrl,
                        sonarToken: '${sonar_token}'
                    )
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                buildDockerImage(
                    DOCKER_REGISTRY: params.DOCKER_REGISTRY,
                    DOCKER_REPO: params.DOCKER_REPO,
                    IMAGE_NAME: params.IMAGE_NAME,
                    BUILD_NUMBER: params.BUILD_NUMBER
                )
            }
        }

        stage('Push Image to Artifactory') {
            steps {
                pushToArtifactory(
                    DOCKER_REGISTRY: params.DOCKER_REGISTRY,
                    DOCKER_REPO: params.DOCKER_REPO,
                    IMAGE_NAME: params.IMAGE_NAME,
                    BUILD_NUMBER: params.BUILD_NUMBER,
                    ARTIFACTORY_CREDENTIALS_ID: params.ARTIFACTORY_CREDENTIALS_ID
                )
            }
        }

        stage('Cleanup Docker Image') {
            steps {
                cleanupDockerImage(
                    DOCKER_REGISTRY: params.DOCKER_REGISTRY,
                    DOCKER_REPO: params.DOCKER_REPO,
                    IMAGE_NAME: params.IMAGE_NAME,
                    BUILD_NUMBER: params.BUILD_NUMBER
                )
            }
        }
    }

    post {
        always {
            script {  
                sh'echo "deployment success"'
                // Add any cleanup actions or notifications here
            }
        }
    }
}
