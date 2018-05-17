#!/usr/bin/env bats

load bats_helpers

setup() {
  aws_asg_setup
}

teardown() {
  aws_asg_teardown
}

run_clean_up_containers() {
  DEBUG=1 bash "${BATS_TEST_DIRNAME}/clean-up-containers.bash"
}

@test "is a no-op if there are no containers" {
  cat >"${BATS_TMPDIR}/returns/docker" <<EOF
EOF

  cat >"${BATS_TMPDIR}/returns/date" <<EOF
20171030T153252
EOF

  run run_clean_up_containers

  [ "${status}" -eq 0 ]
  assert_cmd "clean-up-containers tag=cron time=20171030T153252 level=info msg=\"cron finished\" status=warning killed=0 running=0"
}
