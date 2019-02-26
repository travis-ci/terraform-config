#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  : "${ETCDIR:=/etc}"
  : "${VARTMP:=/var/tmp}"

  export DEBIAN_FRONTEND=noninteractive

  eval "$(tfw printenv docker)"
  __setup_docker
  __install_registry
}

__setup_docker() {
  if [[ -f "${VARTMP}/daemon.json" ]]; then
    cp -v "${VARTMP}/daemon.json" "${ETCDIR}/docker/"
    chmod 0644 "${ETCDIR}/docker/daemon.json"
  fi
}

__install_registry() {
  docker pull registry:2
  docker run --restart=always -v "${VARTMP}/proxy.yml:/etc/registry.conf" -p 5000:5000 registry:2 serve /etc/registry.conf
}

main "${@}"
