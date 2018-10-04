#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  : "${ETCDIR:=/etc}"
  : "${VARTMP:=/var/tmp}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  chown -R travis:travis "${RUNDIR}"

  cp -v "${VARTMP}/travis-worker.service" \
    "${ETCDIR}/systemd/system/travis-worker.service"
  systemctl enable travis-worker || true
  systemctl stop travis-worker || true
  systemctl start travis-worker || true

  __wait_for_docker
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

main "$@"
