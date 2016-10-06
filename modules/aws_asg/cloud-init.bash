#!/usr/bin/env bash
# vim:filetype=sh

set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  : "${ETCDIR:=/etc}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local hosts_line
  local instance_hostname
  local instance_id
  local instance_ipv4
  local syslog_address

  curl -sSL -o "${RUNDIR}/instance-id" \
    'http://169.254.169.254/latest/meta-data/instance-id'
  instance_id="$(cat "${RUNDIR}/instance-id")"

  curl -sSL -o "${RUNDIR}/instance-ipv4" \
    'http://169.254.169.254/latest/meta-data/local-ipv4'
  instance_ipv4="$(cat "${RUNDIR}/instance-ipv4")"

  instance_hostname="$(
    sed "s/___INSTANCE_ID___/${instance_id}/g" \
      "${RUNDIR}/instance-hostname.tmpl"
  )"
  hosts_line="${instance_ipv4} ${instance_hostname} ${instance_hostname%%.*}"
  syslog_address="$(cat "${RUNDIR}/syslog-address")"

  sed -i \
    "s/___INSTANCE_ID___/${instance_id}/g" "${ETCDIR}/default/travis-worker"*

  echo "${instance_hostname}" \
    | tee "${ETCDIR}/hostname" >"${RUNDIR}/instance-hostname"
  hostname -F "${ETCDIR}/hostname"

  if ! grep -q "^${hosts_line}" "${ETCDIR}/hosts"; then
    echo "${hosts_line}" | tee -a "${ETCDIR}/hosts"
  fi

  chown -R travis:travis "${RUNDIR}"

  touch "${ETCDIR}/rsyslog.d/65-papertrail.conf"
  sed -i '/^\*\.\*.*@/d' "${ETCDIR}/rsyslog.d/65-papertrail.conf"
  echo "*.* @${syslog_address}" >>"${ETCDIR}/rsyslog.d/65-papertrail.conf"

  service rsyslog stop || true
  service rsyslog start || true

  service travis-worker stop || true
  service travis-worker start || true
}

main "$@"
