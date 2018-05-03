#!/usr/bin/env bash
# vim:filetype=sh
set -o pipefail
set -o errexit

main() {
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local pupcycler_url pupcycler_auth_token instance_id
  pupcycler_url="$(cat "${RUNDIR}/pupcycler-url")"
  pupcycler_auth_token="$(cat "${RUNDIR}/pupcycler-auth-token")"
  instance_id="$(cat "${RUNDIR}/instance-id-full")"

  curl \
    -f \
    -X POST \
    -H "Authorization: token ${pupcycler_auth_token}" \
    "${pupcycler_url}/startups/${instance_id}"
}

main "$@"
