#!/usr/bin/env bash
set -o errexit

main() {
  local run_d="${RUNDIR}"
  : "${run_d:=/var/tmp/travis-run.d}"

  local error_count
  error_count="$(cat "${run_d}/implode.error-count" 2>/dev/null || echo 0)"

  if [[ -f "${run_d}/implode.confirm" ]]; then
    __handle_implode_confirm "${run_d}"
  fi

  "${DMESG:-dmesg}" | if grep -q unregister_netdevice; then
    __handle_found_unregister_netdevice "${error_count}" "${run_d}"
  fi
}

__handle_implode_confirm() {
  local run_d="${1}"

  : "${POST_SHUTDOWN_SLEEP:=300}"
  : "${SHUTDOWN:=shutdown}"

  rm -vf \
    "${run_d}/implode" \
    "${run_d}/implode.config" \
    "${run_d}/implode.error-count"
  local reason
  reason="$(cat "${run_d}/implode.confirm" 2>/dev/null)"
  : "${reason:=not sure why}"
  # TODO: shutdown with poweroff once mainline kernel upgrade changes are live
  # "${SHUTDOWN}" -P now "imploding because ${reason}"
  "${SHUTDOWN}" -r now "imploding because ${reason}"
  sleep "${POST_SHUTDOWN_SLEEP}"
  exit 0
}

__handle_found_unregister_netdevice() {
  local error_count="${1}"
  local run_d="${2}"

  : "${DOCKER:=docker}"
  : "${MAX_ERROR_COUNT:=4}"

  let error_count+=1
  echo "${error_count}" >"${run_d}/implode.error-count"

  if [[ "${error_count}" -lt "${MAX_ERROR_COUNT}" ]]; then
    return 0
  fi

  echo "detected unregister_netdevice via dmesg count=${error_count}" \
    | tee "${run_d}/implode"
  "${DOCKER}" kill -s INT travis-worker
}

main "$@"
