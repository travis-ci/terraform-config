#!/bin/bash
set -e
set -o pipefail

__die() {
  local status="${1}"
  local code="${2}"
  local killed_count="${3}"
  local not_killed_count="${4}"
  logger "time=$(date -u +%Y%m%dT%H%M%S) " \
    "prog=$(basename "${0}") status=${status} killed_count=${killed_count} not_killed_count=${not_killed_count}"
  __report_kills "$killed_count" "$not_killed_count"
  exit "${code}"
}

__report_kills() {
  count_killed="$1"
  count_not_killed="$2"
  timestamp="$(date +%s)"

  # request_body=$(< <(cat <<EOF)
  # read -r -d '' request_body <<EOF
  request_body=$(
    cat <<EOF
  { "measure_time": "$timestamp",
    "source": "cron.ec2.aj.container-killer",
    "gauges": [
      {
        "name": "cron.containers.killed",
        "value": "$count_killed",
        "source": "$instance_id"
      },
      {
        "name": "cron.containers.not-killed",
        "value": "$count_not_killed",
        "source": "$instance_id"
      }
    ]
  }
EOF
  )

  curl \
    -u "$LIBRATO_CREDENTIALS" \
    -H "Content-Type: application/json" \
    -d $"$request_body" \
    -X POST \
    "${LIBRATO_API}/v1/metrics"
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
  # shellcheck disable=SC2153
  : "${MAX_AGE:=10800}"
  : "${CREDS_FILE:=/etc/default/travis-worker}"
  : "${LIBRATO_API:=https://metrics-api.librato.com}"
  : "${LIBRATO_USERNAME:=${TRAVIS_WORKER_LIBRATO_EMAIL}}"
  : "${LIBRATO_TOKEN:=${TRAVIS_WORKER_LIBRATO_TOKEN}}"
  : "${LIBRATO_CREDENTIALS:=${LIBRATO_USERNAME}:${LIBRATO_TOKEN}}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local instance_id cids killed_count not_killed_count max_age
  max_age="${MAX_AGE}"
  killed_count=0
  not_killed_count=0
  cids=$(docker ps -q)
  instance_id="$(cat "${RUNDIR}/instance-id")"

  if [ -z "$cids" ]; then
    __die noop 0 0 0
  fi

  for cid in $cids; do
    # Don't kill travis-worker
    if [[ "$(docker inspect "$cid" --format '{{ .Name }}')" == "/travis-worker" ]]; then
      not_killed_count="$((not_killed_count + 1))"
      continue
    fi
    if ! __container_is_newer_than "$cid" "$max_age"; then
      name="$(docker inspect "$cid" --format '{{ .Name }}')"
      logger "$cid is older than $max_age; killing it! ($name)"
      docker kill "$cid"
      killed_count="$((killed_count + 1))"
    else
      not_killed_count="$((not_killed_count + 1))"
    fi
  done
  __die killed 0 "$killed_count" "$not_killed_count"
}

main "$@"
