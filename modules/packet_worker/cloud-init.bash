#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  if [[ ! "${QUIET}" ]]; then
    set -o xtrace
  fi

  : "${ETCDIR:=/etc}"
  : "${VARTMP:=/var/tmp}"
  : "${DEV:=/dev}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  if ! docker version 2>/dev/null; then
    __install_docker
  fi

  if ! getent passwd travis; then
    useradd travis
  fi

  groups travis | if ! grep -q docker; then
    usermod -a -G docker travis
  fi

  __set_aio_max_nr

  chown -R travis:travis "${RUNDIR}"

  if [[ -d "${ETCDIR}/systemd/system" ]]; then
    cp -v "${VARTMP}/travis-worker.service" \
      "${ETCDIR}/systemd/system/travis-worker.service"
    systemctl enable travis-worker || true
  fi

  systemctl stop travis-worker || true
  systemctl start travis-worker || true

  echo "___INSTANCE_ID___-$(hostname)" >"${RUNDIR}/instance-hostname.tmpl"

  eval "$(travis-tfw-combined-env travis-network)"

  ## FIXME: this routing is not working but whyyyy
  ## {
  # if [[ "${TRAVIS_NETWORK_VLAN_GATEWAY}" ]]; then
  #   ip route | if ! grep -q "^default via ${TRAVIS_NETWORK_VLAN_GATEWAY}"; then
  #     ip route del default || true
  #     sleep 5
  #     ip route add default via "${TRAVIS_NETWORK_VLAN_GATEWAY}" || true
  #   fi
  # fi
  ## }

  __wait_for_docker
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

__install_docker() {
  curl -Ls https://get.docker.io | bash
}

__set_aio_max_nr() {
  # NOTE: we do this mostly to ensure file IO chatty services like mysql will
  # play nicely with others, such as when multiple containers are running mysql,
  # which is the default on precise + trusty.  The value we set here is 16^5,
  # which is one power higher than the default of 16^4 :sparkles:.
  sysctl -w fs.aio-max-nr=1048576
}

main "$@"
