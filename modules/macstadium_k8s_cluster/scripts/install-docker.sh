#!/bin/bash

if command -v docker >/dev/null 2>&1; then
  echo "Docker is already installed. Skipping."
  exit 0
fi

# install docker from the official repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt-get update
apt-get install -y docker-ce

docker version
