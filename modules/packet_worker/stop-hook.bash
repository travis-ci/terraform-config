#!/usr/bin/env bash
# vim:filetype=sh
set -o pipefail
set -o errexit

main() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local pupcycler_url pupcycler_auth_token instance_id post_stop_sleep
  pupcycler_url="$(cat "${RUNDIR}/pupcycler-url")"
  instance_id="$(cat "${RUNDIR}/instance-id-full")"
  pupcycler_auth_token="$(cat "${RUNDIR}/pupcycler-auth-token")"
  post_stop_sleep="$(cat "${RUNDIR}/post-stop-sleep" 2>/dev/null || echo 300)"

  curl \
    -f \
    -X POST \
    -H "Authorization: token ${pupcycler_auth_token}" \
    "${pupcycler_url}/shutdowns/${instance_id}"

  sleep "${post_stop_sleep}"
}

main "$@"
