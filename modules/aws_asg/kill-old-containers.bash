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

__container_is_newer_than() {
  cid="$1"
  max_age="$2"
  created=$(date --date="$(docker inspect -f '{{ .Created }}' "$cid")" +%s)
  age=$(($(date +%s) - created))
  if [ "$age" -gt "$max_age" ]; then
    logger "Container $cid age $age is older than max_age of $max_age."
    return 1
  fi
}

main() {
  local cids killed_count
  # shellcheck disable=SC2153
  local max_age="${MAX_AGE}"
  : "${max_age:=10800}"
  killed_count=0
  cids=$(docker ps -q)

  if [ -z "$cids" ]; then
    __die noop 0 0
  fi

  for cid in $cids; do
    # Don't kill travis-worker
    if [[ "$(docker inspect "$cid" --format '{{ .Name }}')" == "/travis-worker" ]]; then
      continue
    fi
    if ! __container_is_newer_than "$cid" "$max_age"; then
      name="$(docker inspect "$cid" --format '{{ .Name }}')"
      logger "$cid is older than $max_age; killing it! ($name)"
      docker kill "$cid"
      killed_count="$((killed_count + 1))"
    fi
  done
  __die killed 0 "$killed_count"
}

main "$@"
