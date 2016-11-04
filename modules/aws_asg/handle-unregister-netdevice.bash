#!/usr/bin/env bash
set -o errexit

main() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${DMESG:=dmesg}"
  : "${DOCKER:=docker}"

  "${DMESG}" | if grep ! -q unregister_netdevice; then
    return 0
  fi

  date -u >"${RUNDIR}/implode"
  "${DOCKER}" kill -s INT travis-worker
}

main "$@"
