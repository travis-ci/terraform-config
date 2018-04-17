#!/bin/bash
set -o errexit
set -o pipefail

main() {
  if [[ "${DEBUG}" ]]; then
    set -o xtrace
  fi

  # shellcheck disable=SC2153
  : "${MAX_AGE:=12000}"
  : "${CREDS_FILE:=/etc/default/travis-worker}"

  # shellcheck source=/dev/null
  source "${CREDS_FILE}"

  : "${LIBRATO_API:=https://metrics-api.librato.com}"
  : "${LIBRATO_USERNAME:=${TRAVIS_WORKER_LIBRATO_EMAIL}}"
  : "${LIBRATO_TOKEN:=${TRAVIS_WORKER_LIBRATO_TOKEN}}"
  : "${LIBRATO_CREDENTIALS:=${LIBRATO_USERNAME}:${LIBRATO_TOKEN}}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local max_age="${MAX_AGE}"
  local killed_count=0
  local not_killed_count=0
  local status=noop

  local cids
  read -r -a cids <<<"$(docker ps -a -q | tr "\n" ' ')"

  if [[ "${#cids[@]}" -eq 0 ]]; then
    __logger warning 'No containers running, aborting'
    __die warning 0 0 0
  fi

  for cid in "${cids[@]}"; do
    local cn
    cn="$(docker inspect "${cid}" --format '{{ .Name }}')"

    if [[ "${cn}" == /travis-worker ]]; then
      not_killed_count="$((not_killed_count + 1))"
      continue
    fi

    if ! __container_is_newer_than "${cid}" "${max_age}"; then
      __logger info "${cid} is older than ${max_age}; removing! (name=${cn})"

      docker kill "${cid}" ||
        __logger warning "failed to kill container name=${cn}"
      docker stop "${cid}" ||
        __logger warning "failed to stop container name=${cn}"
      docker rm -f "${cid}" ||
        __logger warning "failed to remove container name=${cn}"

      killed_count="$((killed_count + 1))"
      status=killed
    else
      not_killed_count="$((not_killed_count + 1))"
    fi
  done
  __die "${status}" 0 "${killed_count}" "${not_killed_count}"
}

__logger() {
  local level="${1}" && shift
  local msg="${1}" && shift
  local now
  now="$(date -u --iso-8601=seconds)"
  local log_msg="tag=cron time=${now} level=${level} msg=\"${msg}\" ${*}"
  logger -t clean-up-containers "${log_msg}"
}

__die() {
  local status="${1}"
  local code="${2}"
  local killed_count="${3}"
  local not_killed_count="${4}"
  __logger info \
    'cron finished' \
    "status=${status}" \
    "killed=${killed_count}" \
    "running=${not_killed_count}"
  __report_kills "${killed_count}" "${not_killed_count}"
  exit "${code}"
}

__report_kills() {
  if [[ "${LIBRATO_CREDENTIALS}" == : ]] ||
    [[ ! "${LIBRATO_CREDENTIALS}" ]]; then
    __logger error 'No Librato credentials defined; not reporting'
    return
  fi

  local count_killed="${1}"
  local count_not_killed="${2}"
  local now
  now="$(date +%s)"
  local site="${TRAVIS_WORKER_TRAVIS_SITE}"
  local stage=staging
  if [[ "${HOSTNAME}" == *"production"* ]]; then
    stage=production
  fi

  local instance_id
  instance_id="$(cat "${RUNDIR}/instance-id")"

  local request_body
  request_body="$(
    cat <<EOF
  {
    "measure_time": "${now}",
    "source": "cron.linux-containers.${site}.${stage}.container-killer",
    "gauges": [
      {
        "name": "cron.containers.${site}.${stage}.killed",
        "value": "${count_killed}",
        "source": "${instance_id}"
      },
      {
        "name": "cron.containers.${site}.${stage}.running",
        "value": "${count_not_killed}",
        "source": "${instance_id}"
      }
    ]
  }
EOF
  )"

  curl \
    -s \
    -u "${LIBRATO_CREDENTIALS}" \
    -H 'Content-Type: application/json' \
    -d $"${request_body}" \
    -X POST \
    "${LIBRATO_API}/v1/metrics"
}

__container_is_newer_than() {
  local cid="${1}"
  local max_age="${2}"

  # Note: if ${cid} no longer exists, we're essentially running `date --date=""`
  # which returns the equivalent of "midnight" of the current date. But 'set -e'
  # should prevent us from attempting to delete nonexistent containers anyway.
  local created
  created="$(date --date="$(docker inspect -f '{{ .Created }}' "${cid}")" +%s)"
  local age
  age="$(($(date +%s) - created))"
  if [[ "${age}" -gt "${max_age}" ]]; then
    __logger info \
      "Container ${cid} age ${age} is older than max_age of ${max_age}."
    return 1
  fi
}

main "${@}"
