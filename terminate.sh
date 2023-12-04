#!/bin/bash
docker stop jenkins-docker
docker rm jenkins-docker

docker stop petclinic-container
docker rm petclinic-container

docker stop jenkins-server
docker rm jenkins-server