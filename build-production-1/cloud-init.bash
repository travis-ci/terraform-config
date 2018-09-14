#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail

main() {
  : "${ETCDIR:=/etc}"
  : "${TMPDIR:=/var/tmp}"
  : "${USRLOCAL:=/usr/local}"
  : "${VARTMP:=/var/tmp}"


  export DEBIAN_FRONTEND=noninteractive
  __disable_unfriendly_services
  __install_tfw

  eval "$(tfw printenv docker)"
  __tfw_bootstrap
  __setup_docker
}

__disable_unfriendly_services() {
  systemctl stop apt-daily-upgrade || true
  systemctl disable apt-daily-upgrade || true
  systemctl stop apt-daily || true
  systemctl disable apt-daily || true
  systemctl stop apparmor || true
  systemctl disable apparmor || true
  systemctl reset-failed
}

__install_tfw() {
  apt-get update -yqq
  apt-get install -yqq curl make

  rm -rf "${TMPDIR}/tfw-install"
  mkdir -p "${TMPDIR}/tfw-install"
  curl -sSL https://api.github.com/repos/travis-ci/tfw/tarball/master |
    tar -C "${TMPDIR}/tfw-install" --strip-components=1 -xzf -
  make -C "${TMPDIR}/tfw-install" install PREFIX="${USRLOCAL}"
}

__tfw_bootstrap() {
  tfw admin-bootstrap
  tfw bootstrap
}

__setup_docker() {
  if [[ -f "${VARTMP}/daemon-direct-lvm.json" ]]; then
    cp -v "${VARTMP}/daemon-direct-lvm.json" "${ETCDIR}/docker/"
    chmod 0644 "${ETCDIR}/docker/daemon-direct-lvm.json"
  fi

  if [[ -d "${VARTMP}/docker-certs" ]]; then
    rsync -av "${VARTMP}/docker-certs/" "${ETCDIR}/docker/"
  fi
}

main "${@}"
