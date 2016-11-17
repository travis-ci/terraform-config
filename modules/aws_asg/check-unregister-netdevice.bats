#!/usr/bin/env bats

load bats_helpers

setup() {
  export POST_SHUTDOWN_SLEEP=0.1
  export SHUTDOWN=shutdown
  aws_asg_setup
}

teardown() {
  aws_asg_teardown
}

run_check_unregister_netdevice() {
  bash "${BATS_TEST_DIRNAME}/check-unregister-netdevice.bash"
}

@test "handles implosion confirmation" {
  echo 'i cannot go on' >"${RUNDIR}/implode.confirm"
  run run_check_unregister_netdevice
  assert_cmd 'shutdown -P now.+imploding because i cannot go on'
  assert_cmd 'sleep 0.1'
  [ "${status}" -eq 42 ]
  [[ "${output}" =~ status=imploded ]]
}

@test "handles implosion confirmation with reasons unknown" {
  touch "${RUNDIR}/implode.confirm"
  run run_check_unregister_netdevice
  assert_cmd 'shutdown -P now.+imploding because not sure why'
  assert_cmd 'sleep 0.1'
  [ "${status}" -eq 42 ]
  [[ "${output}" =~ status=imploded ]]
}

@test "is a no-op if detected errors are below threshold" {
  export MAX_ERROR_COUNT=3
  cat >>"${BATS_TMPDIR}/returns/dmesg" <<EOF
unregister_netdevice: waiting for lo to become free. Usage count = 1
unregister_netdevice: waiting for lo to become free. Usage count = 1
EOF

  run run_check_unregister_netdevice
  assert_cmd 'dmesg'
  [ "${status}" -eq 0 ]
  [[ "${lines[0]}" =~ status=noop ]]
}

@test "triggers an implosion when errors exceed threshold" {
  export MAX_ERROR_COUNT=1
  cat >>"${BATS_TMPDIR}/returns/dmesg" <<EOF
unregister_netdevice: waiting for lo to become free. Usage count = 1
unregister_netdevice: waiting for lo to become free. Usage count = 1
EOF

  run run_check_unregister_netdevice
  assert_cmd 'dmesg'
  assert_cmd 'docker kill -s INT travis-worker'
  [ -f "${RUNDIR}/implode" ]
  [ "${status}" -eq 86 ]
  [[ "${output}" =~ status=imploding ]]
}
