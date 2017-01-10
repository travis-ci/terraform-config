#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  : "${ETCDIR:=/etc}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local instance_id
  instance_id="$(cat "${RUNDIR}/instance-id")"

  for envfile in "${ETCDIR}/default/travis-worker"*; do
    sed -i "s/___INSTANCE_ID___/${instance_id}/g" "${envfile}"
  done

  chown -R travis:travis "${RUNDIR}"

  service travis-worker stop || true
  service travis-worker start || true

  __wait_for_docker

  iptables -t nat -I PREROUTING -p tcp -d '169.254.169.254' \
    --dport 80 -j DNAT --to-destination '192.0.2.1'

  local registry_cidrs
  registry_cidrs=($(cat "${RUNDIR}/registry-cidrs"))

  for cidr in "${registry_cidrs[@]}"; do
    iptables -I DOCKER -s "${cidr}" -j DROP || true
  done
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
