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

  if
    ! grep -q TRAVIS_WORKER_DOCKER_CONTAINER_LABELS \
      "${ETCDIR}/default/travis-worker-local"
  then
    local container_labels="travis.instance_id:${instance_id}"

    if [[ -f "${RUNDIR}/instance-ipv4" ]]; then
      local ipv4_label
      ipv4_label="travis.ipv4:$(cat "${RUNDIR}/instance-ipv4")"
      container_labels="${container_labels},${ipv4_label}"
    fi

    echo "export TRAVIS_WORKER_DOCKER_CONTAINER_LABELS=${container_labels}" |
      tee -a "${ETCDIR}/default/travis-worker-local"
  fi

  for envfile in "${ETCDIR}/default/travis-worker"*; do
    sed -i "s/___INSTANCE_ID___/${instance_id}/g" "${envfile}"
  done

  __set_aio_max_nr

  __set_max_inotify_instances

  chown -R travis:travis "${RUNDIR}"

  cp -v "${VARTMP}/travis-worker.service" \
    "${ETCDIR}/systemd/system/travis-worker.service"
  systemctl enable travis-worker || true
  systemctl stop travis-worker || true
  systemctl start travis-worker || true

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

__set_max_inotify_instances() {
  local poolsize inotify_max
  poolsize="$(awk -F= '/TRAVIS_WORKER_POOL_SIZE/{print $2; exit}' /etc/default/travis-worker 2>/dev/null || true)"
  inotify_max="$((8192 * ${poolsize:-15}))"
  echo "$inotify_max" >/proc/sys/fs/inotify/max_user_instances
  sysctl -w fs.inotify.max_user_instances="$inotify_max"
}

main "$@"
