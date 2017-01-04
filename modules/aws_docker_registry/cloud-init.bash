#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit

main() {
  local http_secret
  local instance_ipv4
  local registry_data=/mnt/registry-data
  local i=0

  while ! docker version; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    sleep 10
    let i+=10
  done

  http_secret="$(cat /var/tmp/travis-run.d/http-secret)"
  instance_ipv4="$(
    curl -sSL "http://169.254.169.254/latest/meta-data/local-ipv4"
  )"

  mkdir -p "${registry_data}"
  mkfs.xfs /dev/xvdb
  mount -t xfs /dev/xvdb "${registry_data}" || true

  docker rm --force registry || true
  docker run \
    -d \
    --restart=always \
    --name registry \
    -p 8000:8000 \
    -v /var/tmp:/var/tmp \
    -v "${registry_data}:/var/lib/registry" \
    -e "REGISTRY_HTTP_HOST=http://${instance_ipv4}" \
    -e "REGISTRY_HTTP_SECRET=${http_secret}" \
    -e 'REGISTRY_HTTP_ADDR=0.0.0.0:8000' \
    -e 'REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io' \
    registry:2
}

main "$@"
