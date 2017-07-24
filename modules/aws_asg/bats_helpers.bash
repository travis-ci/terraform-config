#!/usr/bin/env bash

aws_asg_setup() {
  export RUNDIR="${BATS_TMPDIR}/run"
  export ETCDIR="${BATS_TMPDIR}/etc"
  export VARTMP="${BATS_TMPDIR}/var/tmp"
  export MOCKLOG="${BATS_TMPDIR}/logs/mock.log"

  mkdir -p \
    "${RUNDIR}" \
    "${VARTMP}" \
    "${ETCDIR}/rsyslog.d" \
    "${ETCDIR}/default" \
    "${ETCDIR}/systemd/system" \
    "${ETCDIR}/init" \
    "${BATS_TMPDIR:?}/bin" \
    "${BATS_TMPDIR}/logs" \
    "${BATS_TMPDIR}/returns"

  rm -f "${MOCKLOG}"

  touch \
    "${ETCDIR}/hosts" \
    "${ETCDIR}/hostname" \
    "${MOCKLOG}" \
    "${VARTMP}/travis-worker.service" \
    "${VARTMP}/travis-worker.conf"

  echo "i-${RANDOM}" >"${RUNDIR}/instance-id"
  echo "flibbity-flob-${RANDOM}.example.com" >"${RUNDIR}/registry-hostname"

  cat >"${ETCDIR}/default/travis-worker-bats" <<EOF
export TRAVIS_TRAVIS_FAFAFAF=galaga
export TRAVIS_TARVIS_SNOOK=fafa/___INSTANCE_ID___/faf
EOF

  cat >"${BATS_TMPDIR}/bin/mock" <<EOF
#!/bin/bash
echo "---> \$(basename \${0})" "\$@" >>${MOCKLOG}
if [[ -f "${BATS_TMPDIR}/returns/\$(basename \${0})" ]]; then
  cat "${BATS_TMPDIR}/returns/\$(basename \${0})"
  exit 0
fi
echo "\${RANDOM}\${RANDOM}\${RANDOM}"
EOF
  chmod +x "${BATS_TMPDIR}/bin/mock"

  for cmd in \
    chown \
    dmesg \
    docker \
    iptables \
    sed \
    service \
    shutdown \
    sleep \
    sysctl \
    systemctl; do
    pushd "${BATS_TMPDIR}/bin" &>/dev/null
    ln -svf mock "${cmd}"
    popd &>/dev/null
  done

  export PATH="${BATS_TMPDIR}/bin:${PATH}"
}

aws_asg_teardown() {
  rm -rf \
    "${RUNDIR}" \
    "${ETCDIR}" \
    "${BATS_TMPDIR:?}/bin" \
    "${BATS_TMPDIR}/logs" \
    "${BATS_TMPDIR}/returns"
}

assert_cmd() {
  grep -E "$1" "${MOCKLOG}"
}
