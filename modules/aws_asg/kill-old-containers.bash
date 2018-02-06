#!/bin/bash
set -e
set -o pipefail

__die() {
  local status="${1}"
  local code="${2}"
  local count="${3}"
  logger "time=$(date -u +%Y%m%dT%H%M%S) " \
    "prog=$(basename "${0}") status=${status} count=${count}"
  exit "${code}"
}

__container_is_too_old() {
  cid="$1"
  expr $(date +%s) - $(date --date="$(docker inspect -f '{{ .Created }}' $cid)" +%s)
}

main() {
  local cids killed_count
  cids=$(docker ps -q)

  if [ -z "$cids" ]; then
    __die noop 0 0
  fi

  for cid in $cids; do
    # Don't kill travis-worker
    if [[ "$(docker inspect "$cid" --format '{{ .Name }}')" == "/travis-worker" ]]; then
      continue
    fi
    age="$(expr $(date +%s) - $(date --date="$(docker inspect -f '{{ .Created }}' "$cid")" +%s))"
    if [ "$age" -gt 10800 ]; then
      logger "$cid is older than 10800; killing it! (age: $age)"
      docker kill "$cid"
      killed_count="$(($count + 1))"
    fi
  done
  __die killed 0 "$count"
}

main "$@"
