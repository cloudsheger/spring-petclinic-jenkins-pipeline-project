@Library('jenkins-devops-libs') _

pipeline {
    agent any

    environment {
        // Move variables that are not configurable at runtime
        JDK_HOME = tool 'jdk8'
        MAVEN_HOME = tool 'Maven 3.9.5'
        PATH = "${MAVEN_HOME}/bin:${JDK_HOME}/bin:${env.PATH}"

        // Set the credentials with default values
        artifactory_credentials = credentials('admin.jfrog')
        sonar_token = credentials('SONAR_TOKEN_ID') 
    }

    parameters {

        string(name: 'ProjectKey', defaultValue: 'shared-lib', description: 'SonarQube project key')
        string(name: 'ProjectName', defaultValue: 'shared-lib', description: 'SonarQube project name')
        string(name: 'SonarHostUrl', defaultValue: 'http://3.91.247.172:9000', description: 'SonarQube server URL')
        string(name: 'GIT_REPO', defaultValue: 'https://github.com/cloudsheger/spring-petclinic-jenkins-pipeline-project.git', description: 'GitHub repo')
        string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'GitHub branch name')

        string(name: 'dockerRegistry', defaultValue: 'shegerlab23.jfrog.io', description: 'Artifactory Docker registry URL')
        string(name: 'dockerRepo', defaultValue: 'docker', description: 'Artifactory Docker repository name')
        string(name: 'imageName', defaultValue: 'petclinic', description: 'Docker image name')
        string(name: 'BUILD_NUMBER', defaultValue: env.BUILD_NUMBER, description: 'Build number')
        // Artifactory Related

        string(name: 'DOCKER_REGISTRY', defaultValue: 'cloudsheger.jfrog.io', description: 'Artifactory Docker registry URL')
        string(name: 'DOCKER_REPO', defaultValue: 'docker', description: 'Artifactory Docker repository name')
        string(name: 'IMAGE_NAME', defaultValue: 'petclinic', description: 'Docker image name')
        string(name: 'BUILD_NUMBER', defaultValue: env.BUILD_NUMBER, description: 'Build number')
        string(name: 'ARTIFACTORY_CREDENTIALS_ID', defaultValue: 'your-artifactory-credentials-id', description: 'Artifactory credentials ID')
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

        stage('SonarQube Code Analysis') {
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
                    DOCKER_REGISTRY: params.dockerRegistry,
                    DOCKER_REPO: params.dockerRepo,
                    IMAGE_NAME: params.imageName,
                    BUILD_NUMBER: params.BUILD_NUMBER
                )
            }
        }
        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Call the shared library function
                    buildAndPushDockerImage([
                        DOCKER_REGISTRY: params.DOCKER_REGISTRY,
                        DOCKER_REPO: params.DOCKER_REPO,
                        IMAGE_NAME: params.IMAGE_NAME,
                        BUILD_NUMBER: params.BUILD_NUMBER,
                        ARTIFACTORY_CREDENTIALS_ID: '${artifactory_credentials}'
                    ])
                }
            }
        }

        stage('Build and Push to Artifactory') {
            steps {
                withCredentials([string(credentialsId: 'ARTIFACTORY_CREDENTIALS_ID', variable: 'artifactory_credentials')]) {
                    pushToArtifactory(
                        dockerRegistry: params.dockerRegistry,
                        dockerRepo: params.dockerRepo,
                        imageName: params.imageName,
                        //BUILD_NUMBER: params.BUILD_NUMBER,
                        artifactory_credentials: "${artifactory-credentials}"
                    )
                }
            }
        }

        stage('Push Image to Artifactory') {
            steps {
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
