#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  [[ "${QUIET}" ]] || set -o xtrace

  : "${DEV:=/dev}"
  : "${ETCDIR:=/etc}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${VARLIBDIR:=/var/lib}"
  : "${VARLOGDIR:=/var/log}"
  : "${VARTMP:=/var/tmp}"

  export DEBIAN_FRONTEND=noninteractive
  chown nobody:nogroup "${VARTMP}"
  chmod 0777 "${VARTMP}"

  for substep in \
    docker_registry; do
    logger running setup substep="${substep}"
    "__setup_${substep}"
  done
}

__wait_for_docker() {
  local i=0

  while ! docker version; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    systemctl start docker &>/dev/null || true
    sleep 10
    let i+=10
  done
}

__setup_docker_registry() {

  apt update -yqq
  apt install docker.io -y
  # docker pull gcr.io/travis-ci-prod-oss-4/registry:v2.7.0-167-g551158e6
  # docker tag gcr.io/travis-ci-prod-oss-4/registry:v2.7.0-167-g551158e6 registry:2
  docker run -d -p 443:443 --restart=always --name registry --env-file /etc/docker/registry/env -v /etc/docker/registry/config.yml:/etc/docker/registry/config.yml -v /etc/ssl/docker:/etc/ssl/docker -v /var/lib/registry:/var/lib/registry registry:2

}

main "${@}"
