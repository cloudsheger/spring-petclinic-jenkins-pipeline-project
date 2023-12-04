#!/bin/bash
# Create a Docker volume for SonarQube data
docker volume create sonarqube-data

# Run the SonarQube container with a mounted volume for data persistence
docker run --name sonarqube --network monitor-net -d \
  -p 9000:9000 -p 9092:9092 \
  -v sonarqube-data:/opt/sonarqube/data \
  -v sonarqube-extensions:/opt/sonarqube/extensions \
  -v sonarqube-plugins:/opt/sonarqube/lib/bundled-plugins \
  sonarqube:latest
