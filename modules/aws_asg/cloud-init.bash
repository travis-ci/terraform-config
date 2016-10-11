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
}

main "$@"
