#!/bin/bash
set -e
set -o pipefail

__logger() {
  level="${1}" && shift
  msg="${1}" && shift
  date="$(date --iso-8601=seconds)"
  log_msg="tag=cron time=${date} level=${level} msg=\"${msg}\" ${*}"
  logger -t "$(basename "${0}")" "${log_msg}"
}

__die() {
  local status="${1}"
  local code="${2}"
  __logger "info" \
    "cron finished" \
    "status=${status}"
  exit "${code}"
}

report_greedy_containers() {
  max_cpu="${1}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  instance_id="$(cat "${RUNDIR}/instance-id")"
  instance_ip="$(cat "${RUNDIR}/instance-ipv4")"

  IFS=$'\n'
  cpu_usage="$(docker stats --no-stream --format "{{.Container}} {{.CPUPerc}} {{.Name}}")"

  if [ -z "${cpu_usage}" ]; then
    __logger "info" \
      "no containers running" \
      "status=noop" \
      "instance_id=${instance_id}" \
      "instance_ip=${instance_ip}"
  fi

  for line in ${cpu_usage}; do
    IFS=" "
    echo "${line}" | while read -r cid usage_as_float name; do
      if [[ "${name}" == "travis-worker" ]]; then
        continue
      fi

      usage_as_int=${usage_as_float%.*}
      if [ "${usage_as_int}" -gt "${max_cpu}" ]; then
        echo "${cid} ${usage_as_int} ${name}"
        __logger "warning" \
          "high cpu usage detected" \
          "status=noop" \
          "instance_id=${instance_id}" \
          "instance_ip=${instance_ip}" \
          "cid=${cid}" \
          "cpu_usage=${usage_as_float}" \
          "name=${name}"
      fi
    done
  done
}

main() {
  # shellcheck disable=SC2153
  : "${MAX_CPU:=100}"

  local max_cpu
  max_cpu="${MAX_CPU}"

  {
    report_greedy_containers "${max_cpu}" | while read -r greedy_cid; do
      echo "greedy cid: ${greedy_cid}"
    done
  }
}

main "$@"
