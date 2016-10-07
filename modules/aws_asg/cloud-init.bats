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

  echo "i-${RANDOM}" >"${RUNDIR}/instance-id"

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

  for cmd in sed service; do
    pushd "${BATS_TMPDIR}/bin" &>/dev/null
    ln -svf mock "${cmd}"
    popd &>/dev/null
  done

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

@test "replaces instance id in env files" {
  run_cloud_init
  assert_cmd 'sed.*___INSTANCE_ID___.*travis-worker-bats'
}

@test "restarts travis-worker" {
  run_cloud_init
  assert_cmd 'service travis-worker stop'
  assert_cmd 'service travis-worker start'
}
