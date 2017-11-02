#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  : "${ETCDIR:=/etc}"
  : "${VARTMP:=/var/tmp}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${WORKER_SUFFIXES:=a b c}"

  chown -R travis:travis "${RUNDIR}"

  if [[ -d "${ETCDIR}/systemd/system" ]]; then
    for worker_suffix in ${WORKER_SUFFIXES}; do
      cp -v "${VARTMP}/travis-worker.service" \
        "${ETCDIR}/systemd/system/travis-worker-${worker_suffix}.service"
      systemctl enable "travis-worker-${worker_suffix}" || true
    done
  fi

  if [[ -d "${ETCDIR}/init" ]]; then
    for worker_suffix in ${WORKER_SUFFIXES}; do
      cp -v "${VARTMP}/travis-worker.conf" \
        "${ETCDIR}/init/travis-worker-${worker_suffix}.conf"
    done
  fi

  for worker_suffix in ${WORKER_SUFFIXES}; do
    service "travis-worker-${worker_suffix}" stop || true
    service "travis-worker-${worker_suffix}" start || true
  done

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

main "$@"
