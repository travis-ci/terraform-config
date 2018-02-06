#!/usr/bin/env bats

load bats_helpers

setup() {
  export MAX_AGE=10800
  aws_asg_setup
}

teardown() {
  aws_asg_teardown
}

run_kill_old_containers() {
  bash "${BATS_TEST_DIRNAME}/kill-old-containers.bash"
}

@test "removes containers older than 3 hours" {
  cat >"${BATS_TMPDIR}/returns/docker" <<EOF
4b4b1e76884b
e2f6756f92d7
75e342138b9e
f2dc4be5a304
9153fe19ef63
32b7af38a72a
098460f0b007
76ca3e25d62a
83a9c5a0eb61
EOF

  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF

  run run_kill_old_containers

  [ "${status}" -eq 0 ]
  assert_cmd "logger time=20171030T153252  prog=kill-old-containers.bash status=killed count=9"
}

@test "is a no-op if there are no containers" {
  cat >"${BATS_TMPDIR}/returns/docker" <<EOF
EOF

  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF

  run run_kill_old_containers

  [ "${status}" -eq 0 ]
  assert_cmd "logger time=20171030T153252  prog=kill-old-containers.bash status=noop count=0"
}

@test "is a no-op if only travis-worker container is running" {
  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF

  cat >"${BATS_TMPDIR}/returns/docker" <<EOF
/travis-worker
EOF

  run run_kill_old_containers

  [ "${status}" -eq 0 ]

  assert_cmd "logger time=20171030T153252  prog=kill-old-containers.bash status=killed count=0"
}
