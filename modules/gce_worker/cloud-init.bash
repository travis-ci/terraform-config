#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  chown -R travis:travis "${RUNDIR}"

  service travis-worker stop || true
  service travis-worker start || true
}

main "$@"
