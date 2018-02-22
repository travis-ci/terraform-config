#!/usr/bin/env bash
# vim:filetype=sh
set -o errexit
set -o pipefail
shopt -s nullglob

main() {
  : "${ETCDIR:=/etc}"
  : "${VARTMP:=/var/tmp}"
  : "${RUNDIR:=/var/tmp/travis-run.d}"

  local instance_id
  instance_id="$(cat "${RUNDIR}/instance-id")"

  for envfile in "${ETCDIR}/default/travis-worker"*; do
    sed -i "s/___INSTANCE_ID___/${instance_id}/g" "${envfile}"
  done

  __set_aio_max_nr

  chown -R travis:travis "${RUNDIR}"

  if [[ -d "${ETCDIR}/systemd/system" ]]; then
    cp -v "${VARTMP}/travis-worker.service" \
      "${ETCDIR}/systemd/system/travis-worker.service"
    systemctl enable travis-worker || true
  fi

  if [[ -d "${ETCDIR}/init" ]]; then
    cp -v "${VARTMP}/travis-worker.conf" \
      "${ETCDIR}/init/travis-worker.conf"
  fi

  service travis-worker stop || true
  service travis-worker start || true

  # The command below drops any requests to the AWS metadata API.
  iptables -I FORWARD -d 169.254.169.254 -j REJECT

  __wait_for_docker

  local registry_hostname
  registry_hostname="$(cat "${RUNDIR}/registry-hostname")"

  set +o pipefail
  set +o errexit
  # The loop of commands below drops any in-container traffic (which goes
  # through the -I DOCKER chain) that attempts to talk to the docker registry host(s),
  # and also drops anything destined for 128.0.0.0/16 (plus other reserved ranges)
  reserved_ranges=(
    128.0.0.0/16
  )
  dig +short "${registry_hostname}" | while read -r ipv4; do
    iptables -I DOCKER -s "${ipv4}" -j DROP || true
    for r in "${reserved_ranges[@]}"; do
      iptables -I DOCKER -d "${r}" -j DROP || true
    done
  done
}

__wait_for_docker() {
  local i=0

  while ! docker version; do
    if [[ $i -gt 600 ]]; then
      exit 86
    fi
    start docker &>/dev/null || true
    sleep 10
    let i+=10
  done
}

__set_aio_max_nr() {
  # NOTE: we do this mostly to ensure file IO chatty services like mysql will
  # play nicely with others, such as when multiple containers are running mysql,
  # which is the default on trusty.  The value we set here is 16^5, which is one
  # power higher than the default of 16^4 :sparkles:.
  sysctl -w fs.aio-max-nr=1048576
}

main "$@"
