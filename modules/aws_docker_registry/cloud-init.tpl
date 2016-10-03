#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit

main() {
  __log main begin "$LINENO"
  __install_docker
  __wait_for_docker
  __write_registry_auth
  __start_registry_container
  __set_hostname
  __log main end "$LINENO"
}

__install_docker() {
  __log install-docker begin "$LINENO"

  apt-get update -yqq
  apt-get install -yqq curl apt-transport-https ca-certificates
  apt-key adv \
    --keyserver hkp://p80.pool.sks-keyservers.net:80 \
    --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  cat >/etc/apt/sources.list.d/docker.list <<EOF
deb https://apt.dockerproject.org/repo ubuntu-trusty main
EOF
  apt-get update -yqq
  apt-get install -yqq docker-engine
  service docker start
  docker run hello-world

  __log install-docker end "$LINENO"
}

__wait_for_docker() {
  __log wait-for-docker begin "$LINENO"
  local i=0
  while ! docker version ; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    sleep 10
    let i+=10
  done
  __log wait-for-docker end "$LINENO"
}

__write_registry_auth() {
  # declared for shellcheck
  local worker_auth

  __log write-registry-auth begin "$LINENO"

  apt-get update -yqq
  apt-get install -yqq apache2-utils
  htpasswd -b -B -c /var/tmp/htpasswd travis-worker "${worker_auth}"

  __log write-registry-auth end "$LINENO"
}

__start_registry_container() {
  # declared for shellcheck
  local letsencrypt_email
  local instance_hostname

  __log start-registry-container begin "$LINENO"

  docker run -d \
    --restart=always \
    --name registry \
    -p 5000:443 \
    -v /var/tmp:/var/tmp \
    -e "REGISTRY_HTTP_ADDR=:5000" \
    -e "REGISTRY_HTTP_AUTH_HTPASSWD_PATH=/var/tmp/htpasswd" \
    -e "REGISTRY_HTTP_AUTH_HTPASSWD_REALM=realmy-mcrealmface" \
    -e "REGISTRY_HTTP_HOST=https://${instance_hostname}" \
    -e "REGISTRY_HTTP_TLS_LETSENCRYPT_CACHEFILE=/var/tmp/letsencrypt.cache" \
    -e "REGISTRY_HTTP_TLS_LETSENCRYPT_EMAIL=${letsencrypt_email}" \
    registry:2
  __log start-registry-container end "$LINENO"
}

__set_hostname() {
  __log set-hostname begin "$LINENO"
  # declared for shellcheck
  local instance_hostname

  local instance_ipv4

  # shellcheck disable=SC2034
  instance_ipv4="$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')"

  local hosts_line="$instance_ipv4 ${instance_hostname} $${instance%.*}"

  echo "${instance_hostname}" | tee /etc/hostname
  hostname -F /etc/hostname
  echo "$hosts_line" | tee -a /etc/hosts
  __log set-hostname end "$LINENO"
}

__log() {
  echo "time=$(date -u +%Y-%m-%dT%H:%M:%S) " \
    "type=cloud-init step=$1 state=$2 line=$3"
}

main "$@"
