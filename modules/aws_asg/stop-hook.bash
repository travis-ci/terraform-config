#!/usr/bin/env bash
# vim:filetype=sh
set -o pipefail
set -o errexit

main() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local cyclist_url
  local instance_id
  local instance_token
  local post_stop_sleep

  cyclist_url="$(cat "${RUNDIR}/cyclist-url")"
  instance_id="$(cat "${RUNDIR}/instance-id")"
  instance_token="$(cat "${RUNDIR}/instance-token")"
  post_stop_sleep="$(cat "${RUNDIR}/post-stop-sleep" 2>/dev/null || echo 300)"

  curl \
    -f \
    -X POST \
    -H "Authorization: token ${instance_token}" \
    "${cyclist_url}/terminations/${instance_id}"

  sleep "${post_stop_sleep}"
}

main "$@"
