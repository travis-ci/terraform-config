#!/usr/bin/env bash
set -o errexit

main() {
  : "${DMESG:=dmesg}"
  : "${DOCKER:=docker}"
  : "${MAX_ERROR_COUNT:=4}"
  : "${POST_SHUTDOWN_SLEEP:=300}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"
  : "${SHUTDOWN:=shutdown}"

  local error_count
  error_count="$(cat "${RUNDIR}/implode.error-count" 2>/dev/null || echo 0)"

  if [[ -f "${RUNDIR}/implode.confirm" ]]; then
    local reason
    reason="$(cat "${RUNDIR}/implode.confirm" 2>/dev/null)"
    : "${reason:=not sure why}"
    "${SHUTDOWN}" -P now "imploding because ${reason}"
    sleep "${POST_SHUTDOWN_SLEEP}"
    return 0
  fi

  "${DMESG}" | if ! grep -q unregister_netdevice; then
    return 0
  fi

  let error_count+=1
  echo "${error_count}" >"${RUNDIR}/implode.error-count"

  if [[ "${error_count}" -lt "${MAX_ERROR_COUNT}" ]]; then
    return 0
  fi

  echo "detected unregister_netdevice via dmesg count=${error_count}" \
    | tee "${RUNDIR}/implode"
  "${DOCKER}" kill -s INT travis-worker
}

main "$@"
