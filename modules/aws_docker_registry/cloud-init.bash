#!/usr/bin/env bash
set -o errexit

main() {
  local registry_data=/mnt/registry-data
  local registry_device=/dev/xvdb
  local http_secret_file=/var/tmp/travis-run.d/http-secret

  __wait_for_docker
  __mount_registry_data "${registry_device}" "${registry_data}"
  __start_registry_container "${registry_data}" "${http_secret_file}"
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

__mount_registry_data() {
  local registry_device="${1}"
  local registry_data="${2}"
  local mounted
  mounted="$(mount -l -t xfs | grep "${registry_device}")"

  if [[ -n "${mounted}" ]]; then
    return
  fi

  mkdir -p "${registry_data}"
  mkfs.xfs -f "${registry_device}"
  mount -t xfs "${registry_device}" "${registry_data}" || true
  touch "${registry_data}/.mounted"
  chown -R registry:registry "${registry_data}"
  chmod 0755 "${registry_data}"
}

__start_registry_container() {
  local registry_data="${1}"
  local http_secret_file="${2}"

  docker rm --force registry || true
  docker run \
    -d \
    --restart=always \
    --name registry \
    -p 8000:8000 \
    -v /var/tmp:/var/tmp \
    -v "${registry_data}:/var/lib/registry" \
    -e "REGISTRY_HTTP_HOST=http://$(__get_private_ipv4)" \
    -e "REGISTRY_HTTP_SECRET=$(__get_http_secret "${http_secret_file}")" \
    -e 'REGISTRY_HTTP_ADDR=0.0.0.0:8000' \
    -e 'REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io' \
    --userns host \
    -u "$(id -u registry)" \
    registry:2
}

__get_http_secret() {
  local http_secret_file="${1}"
  local http_secret=notasecret

  if [[ -s "${http_secret_file}" ]]; then
    http_secret="$(cat "${http_secret_file}" 2>/dev/null)"
  fi
  echo "${http_secret}"
}

__get_private_ipv4() {
  curl -sSL "http://169.254.169.254/latest/meta-data/local-ipv4" 2>/dev/null
}

main "$@"
