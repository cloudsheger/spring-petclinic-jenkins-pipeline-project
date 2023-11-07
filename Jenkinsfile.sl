@Library('my-shared-library') _

pipeline {
    agent any
    parameters {
        string(name: 'ProjectKey', defaultValue: 'shared-lib', description: 'SonarQube project key')
        string(name: 'ProjectName', defaultValue: 'shared-lib', description: 'SonarQube project name')
        string(name: 'SonarHostUrl', defaultValue: 'http://localhost:9000', description: 'SonarQube server URL')
        string(name: 'SonarToken', defaultValue: '', description: 'SonarQube token')
    }
    stages {
        stage('Example') {
            steps {
                echo "Running example stage"
            }
        }
        stage('SonarQube Scan') {
            steps {
                sonarScanPipeline(
                projectKey: params.ProjectKey, 
                projectName: params.ProjectName, 
                sonarHostUrl: params.SonarHostUrl, 
                sonarToken: params.SonarToken)
            }
        }
    }
}
