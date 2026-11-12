#!/usr/bin/env bash
# Run inside the Lab10 OVS appliance, not the Ubuntu VM.
set -euo pipefail
ovs-vsctl --may-exist add-br my-br
ovs-vsctl set Bridge my-br protocols=OpenFlow13
ovs-vsctl del-controller my-br
ovs-vsctl set-fail-mode my-br secure
for port in eth1 eth2; do
  ovs-vsctl --may-exist add-port my-br "$port"
  ovs-vsctl set Port "$port" vlan_mode=access tag=100
  ip link set "$port" up
done
ovs-vsctl --may-exist add-port my-br eth15
ip link set eth15 up
ovs-ofctl -O OpenFlow13 add-flow my-br 'cookie=0xa000,priority=0,actions=NORMAL'
ovs-vsctl clear Bridge my-br mirrors
ovs-vsctl -- --id=@p get Port eth15 \
  -- --id=@m create Mirror name=lab10-mirror select-all=true output-port=@p \
  -- set Bridge my-br mirrors=@m
