#!/usr/bin/env bats

load bats_helpers

setup() {
  aws_asg_setup
}

teardown() {
  aws_asg_teardown
}

run_cloud_init() {
  bash "${BATS_TEST_DIRNAME}/cloud-init.bash"
}

@test "replaces instance id in env files" {
  run_cloud_init
  assert_cmd 'sed.*___INSTANCE_ID___.*travis-worker-bats'
}

@test "chowns the rundir" {
  run_cloud_init
  assert_cmd "chown -R travis:travis ${RUNDIR}"
}

@test "restarts travis-worker" {
  run_cloud_init
  assert_cmd 'systemctl stop travis-worker'
  assert_cmd 'systemctl start travis-worker'
}

@test "disables access to ec2 metadata api" {
  run_cloud_init
  assert_cmd 'iptables -I FORWARD -d 169.254.169.254 -j REJECT'
}
