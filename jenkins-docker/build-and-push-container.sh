#!/bin/bash
docker build -t cloudsheger/jenkins-docker-latest:latest .
docker push cloudsheger/jenkins-docker-latest:latest