@Library('my-shared-library') _

pipeline {
    agent any

    environment {
        // Move variables that are not configurable at runtime
        JDK_HOME = tool 'jdk8'
        MAVEN_HOME = tool 'Maven 3.9.5'
        PATH = "${MAVEN_HOME}/bin:${JDK_HOME}/bin:${env.PATH}"

        // Set the credentials with default values
        sonar_token = credentials('SONAR_TOKEN_ID') 
        artifactory-credentials = credentials('ARTIFACTORY_CREDENTIALS_ID')
    }

    parameters {

        string(name: 'ProjectKey', defaultValue: 'shared-lib', description: 'SonarQube project key')
        string(name: 'ProjectName', defaultValue: 'shared-lib', description: 'SonarQube project name')
        string(name: 'SonarHostUrl', defaultValue: 'http://localhost:9000', description: 'SonarQube server URL')
        string(name: 'GIT_REPO', defaultValue: 'https://github.com/cloudsheger/spring-petclinic-jenkins-pipeline-project.git', description: 'GitHub repo')
        string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'GitHub branch name')

        string(name: 'DOCKER_REGISTRY', defaultValue: 'cloudsheger.jfrog.io', description: 'Artifactory Docker registry URL')
        string(name: 'DOCKER_REPO', defaultValue: 'docker', description: 'Artifactory Docker repository name')
        string(name: 'IMAGE_NAME', defaultValue: 'petclinic', description: 'Docker image name')
        string(name: 'BUILD_NUMBER', defaultValue: env.BUILD_NUMBER, description: 'Build number')

        // Credentials with default values
        //credentials(name: 'SONAR_TOKEN_ID', description: 'SonarQube Token', defaultValue: 'default-sonar-token')
        //credentials(name: 'ARTIFACTORY_CREDENTIALS_ID', description: 'Artifactory credentials ID', defaultValue: 'default-artifactory-credentials')
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
                        sonarToken: "${sonar_token}"
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

        stage('Build and Push to Artifactory') {
            steps {
                    // Call the shared library
                  withCredentials([string(credentialsId: 'ARTIFACTORY_CREDENTIALS_ID', variable: 'artifactory-credentials')]) {    
                    pushToArtifactory(
                        DOCKER_REGISTRY: params.DOCKER_REGISTRY,
                        DOCKER_REPO: params.DOCKER_REPO,
                        IMAGE_NAME: params.IMAGE_NAME,
                        BUILD_NUMBER: params.BUILD_NUMBER,
                        ARTIFACTORY_CREDENTIALS_ID: "${artifactory-credentials}"
                        )
                }    
            }
        }

        stage('Push Image to Artifactory') {
            steps {
                pushToArtifactory(
                    DOCKER_REGISTRY: params.DOCKER_REGISTRY,
                    DOCKER_REPO: params.DOCKER_REPO,
                    IMAGE_NAME: params.IMAGE_NAME,
                    BUILD_NUMBER: params.BUILD_NUMBER,
                    ARTIFACTORY_CREDENTIALS_ID: env.ARTIFACTORY_CREDENTIALS_ID
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
            cleanWs()
        }
    }
}
