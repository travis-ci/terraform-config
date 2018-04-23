#!/usr/bin/env bats

load bats_helpers

setup() {
  export DOCKER_PS_SLEEP_TIME=2
  export POST_SHUTDOWN_SLEEP=0.1
  export SHUTDOWN=shutdown
  aws_asg_setup
}

teardown() {
  aws_asg_teardown
}

run_check_docker_health() {
  bash "${BATS_TEST_DIRNAME}/check-docker-health.bash"
}

@test "handles implosion confirmation" {
  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF
  echo 'docker appears to be unhealthy' >"${RUNDIR}/implode.confirm"
  run run_check_docker_health

  assert_cmd 'shutdown -P now.+imploding because docker appears to be unhealthy'
  [ "${status}" -eq 42 ]
  assert_cmd "logger time=20171030T153252  prog=check-docker-health.bash status=imploded"
}

@test "handles implosion confirmation when docker is unhealthy" {
  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF

  touch "${RUNDIR}/implode.confirm"

  run run_check_docker_health
  [ "${status}" -eq 42 ]
  assert_cmd "logger time=20171030T153252  prog=check-docker-health.bash status=imploded"
}

@test "is a no-op if uptime is too low" {
  # an empty result means 'docker ps' has not responded...
  cat >"${BATS_TMPDIR}/returns/timeout" <<EOF
EOF

  # ...but an empty result should not trigger an imposion if the instance is new
  cat >"${BATS_TMPDIR}/returns/awk" <<EOF
60
EOF

  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF

  run run_check_docker_health
  [ "${status}" -eq 0 ]
  assert_cmd "logger time=20171030T153252  prog=check-docker-health.bash status=noop"
}

@test "is a no-op if docker ps is ok" {
  # 'docker ps' returns a result and should be considered healthy
  cat >"${BATS_TMPDIR}/returns/timeout" <<EOF
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
EOF

  cat >"${RUNDIR}/implode" <<EOF
EOF

  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF

  run run_check_docker_health

  [ "${status}" -eq 0 ]
  assert_cmd "logger time=20171030T153252  prog=check-docker-health.bash status=noop"
}

@test "triggers an implosion when docker is unhealthy" {
  # an empty result means 'docker ps' has not responded...
  cat >"${BATS_TMPDIR}/returns/timeout" <<EOF
EOF

  # ...and the instance has been running long enough for us to expect docker to respond
  cat >"${BATS_TMPDIR}/returns/awk" <<EOF
60000
EOF

  cat >"${BATS_TMPDIR}/returns/pidof" <<EOF
42
EOF

  cat >"${RUNDIR}/implode" <<EOF
docker appears to be unhealthy
EOF

  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF

  run run_check_docker_health
  assert_cmd "kill_mocked -TERM 42"

  [ -f "${RUNDIR}/implode" ]
  [ "${status}" -eq 86 ]
  assert_cmd "logger time=20171030T153252  prog=check-docker-health.bash status=imploding"
}
