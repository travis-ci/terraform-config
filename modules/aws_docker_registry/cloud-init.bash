#!/usr/bin/env bash
set -o errexit

main() {
  local registry_defaults=/etc/default/registry

  if [[ -f "${registry_defaults}" ]]; then
    # shellcheck source=/dev/null
    source "${registry_defaults}"
  fi

  __wait_for_docker
  __start_registry_container "${registry_defaults}"
}

__wait_for_docker() {
  local i=0

  while ! docker version; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    start docker &>/dev/null || true
    sleep 10
    let i+=10
  done
}

__start_registry_container() {
  local registry_defaults="${1}"

  docker rm --force registry || true
  docker run \
    -d \
    --restart=always \
    --name registry \
    -p '8000:8000' \
    -v /var/tmp:/var/tmp \
    -v /var/tmp/registry:/etc/docker/registry \
    --env-file "${registry_defaults}" \
    -e "REGISTRY_HTTP_HOST=http://$(__get_private_ipv4)" \
    registry:2
}

__get_private_ipv4() {
  curl -sSL "http://169.254.169.254/latest/meta-data/local-ipv4" 2>/dev/null
}

main "$@"
