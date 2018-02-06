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

__container_is_young() {
  cid="$1"
  created=$(date --date="$(docker inspect -f '{{ .Created }}' "$cid")" +%s)
  age=$(($(date +%s) - created))
  if [ "$age" -gt 10800 ]; then
    echo 1
  fi
}

main() {
  local cids killed_count
  cids=$(docker ps -q)
  killed_count=0

  if [ -z "$cids" ]; then
    __die noop 0 0
  fi

  for cid in $cids; do
    # Don't kill travis-worker
    if [[ "$(docker inspect "$cid" --format '{{ .Name }}')" == "/travis-worker" ]]; then
      continue
    fi
    if [[ ! $(__container_is_young "$cid") ]]; then
      logger "$cid is older than 10800; killing it! (age: $age)"
      echo "docker kill $cid"
      killed_count="$((killed_count + 1))"
    fi
  done
  __die killed 0 "$killed_count"
}

main "$@"
