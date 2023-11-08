@Library('my-shared-library') _

pipeline {

    environment {
        SONAR_TOKEN_ID = credentials('SONAR_TOKEN_ID') // SONAR_TOKEN_ID should be the ID of the Jenkins credentials storing your SonarQube token
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
        //string(name: 'SonarToken', defaultValue: '', description: 'SonarQube token')
    }
    stages {
     stage('Cloning Git') {
      steps {
        git 'https://github.com/cloudsheger/spring-petclinic-jenkins-pipeline.git'
      }
     }
     stage('Compile') {
      steps {
         sh 'mvn compile' //only compilation of the code
       }
     }
     stage('Test & Build') {
      steps {
        sh '''
        mvn clean install
        ls
        pwd
        ''' 
        //if the code is compiled, we test and package it in its distributable format; run IT and store in local repository
      }
     }
     stage('Sonar Static Code Analysis') {
        steps {
            sonarScanPipeline(
            projectKey: params.ProjectKey, 
            projectName: params.ProjectName, 
            sonarHostUrl: params.SonarHostUrl, 
            sonarToken: env.SONAR_TOKEN_ID)
            
        }
     }
     stage ('Quality Gateway'){
		steps {
			qualityGates()
		}
	 }
    }
}
