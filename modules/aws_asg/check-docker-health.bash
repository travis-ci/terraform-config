#!/usr/bin/env bash
set -o pipefail
set -o errexit

# Sometimes, the docker service will be running, but certain commands (docker info) will hang indefinitely.
# This script detects this behavior and implodes the instance when it occurs.

main() {
  local warmup_grace_period=600
  local pre_implosion_sleep="${POST_SHUTDOWN_SLEEP}"
  local sleep_time="${DOCKER_PS_SLEEP_TIME}"
  local run_d="${RUNDIR}"
  : "${pre_implosion_sleep:=300}"
  : "${sleep_time:=5}"
  : "${run_d:=/var/tmp/travis-run.d}"
  : "${KILL_COMMAND:=kill}"

  if [[ -f "${run_d}/implode.confirm" ]]; then
    __handle_implode_confirm "${run_d}"
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
    __handle_unresponsive_docker "${run_d}" "${pre_implosion_sleep}"
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

  local reason
  reason="$(cat "${run_d}/implode.confirm" 2>/dev/null)"
  : "${reason:=not sure why}"
  logger "imploding due to unhealthy docker; shutting down now!"
  "${SHUTDOWN:-/sbin/shutdown}" -P now "imploding because ${reason}"
}

__handle_unresponsive_docker() {
  local run_d="${1}"
  local pre_implosion_sleep="${2}"

  msg="docker is still unhealthy, implosion will continue"
  if [ ! -e "${run_d}/implode" ]; then
    msg="docker appears to be unhealthy, initiating implosion"
    echo "$msg" >"${run_d}/implode"
  fi
  logger "$msg"

  logger "Sleeping ${pre_implosion_sleep}"
  sleep "${pre_implosion_sleep}"

  if [ ! -e "${run_d}/implode" ]; then
    logger "docker previously reported as unhealthy, but ${run_d}/implode not found; not imploding?"
    __die noop 0
  fi

  pid="$(pidof travis-worker)" || true
  if [ -z "$pid" ]; then
    msg="No PID found for travis-worker, and docker is unhealthy; confirming implosion via cron"
    echo "$msg" >"${run_d}/implode.confirm"
    logger "$msg"
  else
    logger "Running '${KILL_COMMAND} -TERM $pid' to kill travis-worker due to unhealthy docker."
    "${KILL_COMMAND}" -TERM "$pid"
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
