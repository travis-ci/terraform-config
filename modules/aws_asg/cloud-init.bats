#!/usr/bin/env bats

setup() {
  export RUNDIR="${BATS_TMPDIR}/run"
  export ETCDIR="${BATS_TMPDIR}/etc"
  export MOCKLOG="${BATS_TMPDIR}/logs/mock.log"

  mkdir -p \
    "${RUNDIR}" \
    "${ETCDIR}/rsyslog.d" \
    "${ETCDIR}/default" \
    "${BATS_TMPDIR}/bin" \
    "${BATS_TMPDIR}/logs" \
    "${BATS_TMPDIR}/returns"

  rm -f "${MOCKLOG}"

  touch "${ETCDIR}/hosts" "${ETCDIR}/hostname"

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

  for cmd in chown curl hostname sed service; do
    pushd "${BATS_TMPDIR}/bin" &>/dev/null
    ln -svf mock "${cmd}"
    popd &>/dev/null
  done

  echo "i-${RANDOM}-___INSTANCE_ID___.foo.example.com" \
    >"${RUNDIR}/instance-hostname.tmpl"

  echo "logs.example.com:${RANDOM}" >"${RUNDIR}/syslog-address"
  export PATH="${BATS_TMPDIR}/bin:${PATH}"
}

teardown() {
  rm -rf \
    "${RUNDIR}" \
    "${ETCDIR}" \
    "${BATS_TMPDIR}/bin" \
    "${BATS_TMPDIR}/logs" \
    "${BATS_TMPDIR}/returns"
}

run_cloud_init() {
  bash "${BATS_TEST_DIRNAME}/cloud-init.bash"
}

assert_cmd() {
  grep -E "$1" "${MOCKLOG}"
}

@test "writes instance id" {
  run_cloud_init
  assert_cmd 'curl.*meta-data/instance-id'
  [ -s "${RUNDIR}/instance-id" ]
}

@test "writes instance ipv4" {
  run_cloud_init
  assert_cmd 'curl.*meta-data/local-ipv4'
  [ -s "${RUNDIR}/instance-ipv4" ]
}

@test "replaces instance id in env files" {
  run_cloud_init
  assert_cmd 'sed.*___INSTANCE_ID___.*travis-worker-bats'
}

@test "sets hostname" {
  run_cloud_init
  assert_cmd "hostname -F ${ETCDIR}/hostname"
}

@test "writes hostname and ipv4 to /etc/hosts" {
  echo 'known.with.dots' >"${BATS_TMPDIR}/returns/curl"
  echo 'other.with.dots' >"${BATS_TMPDIR}/returns/sed"
  run_cloud_init
  grep -qE '^known.with.dots other.with.dots other$' "${ETCDIR}/hosts"
}

@test "sets permissions on rundir" {
  run_cloud_init
  assert_cmd "chown -R travis:travis ${RUNDIR}"
}

@test "appends syslog address to papertrail.conf" {
  run_cloud_init
  assert_cmd "sed -i.*${ETCDIR}/rsyslog\\.d/65-papertrail\\.conf"
  [ -s "${ETCDIR}/rsyslog.d/65-papertrail.conf" ]
}

@test "restarts rsyslog" {
  run_cloud_init
  assert_cmd 'service rsyslog stop'
  assert_cmd 'service rsyslog start'
}

@test "restarts travis-worker" {
  run_cloud_init
  assert_cmd 'service travis-worker stop'
  assert_cmd 'service travis-worker start'
}
