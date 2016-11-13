#!/usr/bin/env bash
set -o errexit

main() {
  # shellcheck disable=SC2153
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local error_count
  error_count="$(cat "${RUNDIR}/implode.error-count" 2>/dev/null || echo 0)"

  if [[ -f "${RUNDIR}/implode.confirm" ]]; then
    __handle_implode_confirm "${RUNDIR}"
  fi

  "${DMESG:-dmesg}" | if grep -q unregister_netdevice; then
    __handle_found_unregister_netdevice "${error_count}"
  fi
}

__handle_implode_confirm() {
  local rundir="${1}"

  : "${POST_SHUTDOWN_SLEEP:=300}"
  : "${SHUTDOWN:=shutdown}"

  rm -vf \
    "${rundir}/implode" \
    "${rundir}/implode.config" \
    "${rundir}/implode.error-count"
  local reason
  reason="$(cat "${rundir}/implode.confirm" 2>/dev/null)"
  : "${reason:=not sure why}"
  "${SHUTDOWN}" -r now "imploding because ${reason}"
  sleep "${POST_SHUTDOWN_SLEEP}"
  exit 0
}

__handle_found_unregister_netdevice() {
  local error_count="${1}"
  local rundir="${2}"

  : "${DOCKER:=docker}"
  : "${MAX_ERROR_COUNT:=4}"

  let error_count+=1
  echo "${error_count}" >"${rundir}/implode.error-count"

  if [[ "${error_count}" -lt "${MAX_ERROR_COUNT}" ]]; then
    return 0
  fi

  echo "detected unregister_netdevice via dmesg count=${error_count}" \
    | tee "${rundir}/implode"
  "${DOCKER}" kill -s INT travis-worker
}

main "$@"
