#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  : "${ETCDIR:=/etc}"
  : "${VARTMP:=/var/tmp}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  if ! docker version; then
    __install_docker
  fi

  if ! getent passwd travis; then
    useradd travis
    usermod -a -G docker travis
  fi

  __set_aio_max_nr

  chown -R travis:travis "${RUNDIR}"

  if [[ -d "${ETCDIR}/init" ]]; then
    cp -v "${VARTMP}/travis-worker.conf" \
      "${ETCDIR}/init/travis-worker.conf"
  fi

  service travis-worker stop || true
  service travis-worker start || true

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
