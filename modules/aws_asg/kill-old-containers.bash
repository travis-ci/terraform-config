#!/bin/bash
set -e

__die() {
  local status="${1}"
  local code="${2}"
  local count="${3}"
  logger "time=$(date -u +%Y%m%dT%H%M%S) " \
    "prog=$(basename "${0}") status=${status} count=${count}"
  exit "${code}"
}

main() {
  worker_cid=$(docker inspect travis-worker --format '{{ .Id }}')
  cids=$(docker ps -q --filter before="$worker_cid")

  if [ -z "$cids" ]; then
    __die noop 0 0
  fi

  for cid in $cids; do
    logger "Removing container older than travis-worker: $(docker ps --filter id="$cid" | grep -v CONTAINER)"
    docker kill "$cid"
  done
  __die killed 0 "$(echo "$cids" | wc -l)"
}

main "$@"
