#!/bin/bash

# Unlike most of the other scripts, this one runs in an "external"
# data source, which means it will run locally on the machine running
# Terraform, rather than on any of the provisioned VMs.
#
# This unfortunately means we need to SSH in to the machine ourselves.

set -e

# Read variables from the "query" data passed from Terraform
eval "$(jq -r '@sh "HOST=\(.host) USER=\(.user)"')"

# Fetch the join command
CMD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "$USER@$HOST" sudo kubeadm token create --print-join-command)

# Produce a JSON object containing the join command
jq -n --arg command "$CMD" '{"command":$command}'
