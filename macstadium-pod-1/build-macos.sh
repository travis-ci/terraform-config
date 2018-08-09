#!/bin/bash

set -o errexit

if tmux has -t packer-build; then
  # We don't want to try to run a build if there might be one already running
  tmux attach -t packer-build
else
  cd ~/packer-templates-mac
  tmux new -ds packer-build

  # Make sure we have our environment loaded
  tmux send-keys -t packer-build.0 "source ~/.packer-env" C-m

  # Run the command the user provided
  command=$(printf '%q ' "$@")
  tmux send-keys -lt packer-build.0 "$command"
  tmux send-keys -t packer-build.0 C-m

  # Attach to the running build
  tmux attach -t packer-build
fi
