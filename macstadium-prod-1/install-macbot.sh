#!/bin/bash

set -o errexit

main() {
  create_docker_swarm
  move_files
  deploy_macbot_stack
}

create_docker_swarm() {
  echo ">>> Creating Docker Swarm if needed"
  docker swarm init >/dev/null 2>&1 || { echo "Docker swarm already exists."; }
}

move_files() {
  echo ">>> Moving service files into place"
  mv /tmp/macbot-env /home/packer/.macbot-env
  mv /tmp/imaged-env /home/packer/.imaged-env
  mv /tmp/macbot.yml /home/packer/macbot.yml
  chown packer:packer /home/packer/*
}

deploy_macbot_stack() {
  echo ">>> Deploying macbot"

  docker pull travisci/macbot:latest
  docker pull travisci/imaged:latest
  docker stack deploy -c /home/packer/macbot.yml macbot
  rm /tmp/ansible-secrets.yml
}

main "$@"
