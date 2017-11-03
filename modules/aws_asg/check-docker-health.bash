#!/usr/bin/env bash
set -o errexit
set -o pipefail

# Sometimes, the docker service will be running, but certain commands (docker info) will hang indefinitely.
# This script detects this behavior and implodes the instance when it occurs.

main() {
  local warmup_grace_period=600
  local post_sleep="${POST_SHUTDOWN_SLEEP}"
  local sleep_time="${DOCKER_PS_SLEEP_TIME}"
  local run_d="${RUNDIR}"
  : "${post_sleep:=300}"
  : "${sleep_time:=5}"
  : "${run_d:=/var/tmp/travis-run.d}"
  : "${KILL_COMMAND:=kill}"

  if [[ -f "${run_d}/implode.confirm" ]]; then
    __handle_implode_confirm "${run_d}" "${post_sleep}"
    __die imploded 42
  fi

  # Don't run this unless instance has been up at least $warmup_grace_period seconds
  uptime_as_int=$(printf "%.0f\n" "$(awk '{ print $1}' /proc/uptime)")
  if [[ "${uptime_as_int}" -lt "${warmup_grace_period}" ]]; then
    logger "Not checking docker health yet, as uptime is still less than ${warmup_grace_period} seconds"
    __die noop 0
  fi

  logger "Checking docker health..."
  result=$(timeout "${sleep_time}"s docker info) || true

  if [ -z "${result}" ]; then
    __handle_unresponsive_docker "${run_d}"
    __die imploding 86
  fi

  if [ -e "${run_d}/implode" ]; then
    logger "docker no longer seems unhealthy; canceling implosion."
    rm "${run_d}/implode"
  fi

  __die noop 0
}

__handle_implode_confirm() {
  local run_d="${1}"
  local post_sleep="${2}"

  local reason
  reason="$(cat "${run_d}/implode.confirm" 2>/dev/null)"
  : "${reason:=not sure why}"
  "${SHUTDOWN:-/sbin/shutdown}" -P now "imploding because ${reason}"
  sleep "${post_sleep}"
}

__handle_unresponsive_docker() {
  local run_d="${1}"
  msg="docker appears to be unhealthy"
  echo "$msg" |
    tee "${run_d}/implode"
  logger "$msg"

  logger "Sleeping ${post_sleep}"
  sleep "${post_sleep}"

  if [ -e "${run_d}/implode" ]; then
    "${KILL_COMMAND}" -TERM "$(pidof travis-worker)" || restart travis-worker
  else
    logger "${run_d}/implode not found, not imploding?"
    __die noop 0
  fi

}

__die() {
  local status="${1}"
  local code="${2}"
  logger "time=$(date -u +%Y%m%dT%H%M%S) " \
    "prog=$(basename "${0}") status=${status}"
  exit "${code}"
}

main "$@"
