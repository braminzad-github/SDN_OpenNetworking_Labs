#!/usr/bin/env bash
# Run INSIDE Branch3; eth10 connects only to the monitoring Cloud.
set -euo pipefail
ovs-vsctl --may-exist add-port project-br eth10
ip link set eth10 up
ovs-vsctl clear Bridge project-br mirrors
ovs-vsctl -- --id=@p get Port eth10 \
  -- --id=@m create Mirror name=project-monitor select-all=true output-port=@p \
  -- set Bridge project-br mirrors=@m
