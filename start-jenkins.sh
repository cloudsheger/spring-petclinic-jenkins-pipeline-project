#!/bin/bash
# Create a Docker volume for Jenkins data
docker volume create jenkins-data
docker network create jenkins-network

# Run the jenkins-docker container with a mounted volume for data persistence
docker run --name jenkins-docker --network jenkins-network -d \
 -u root -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock \
 -v jenkins-data:/var/jenkins_home \
 cloudsheger/jenkins-docker-latest:latest
