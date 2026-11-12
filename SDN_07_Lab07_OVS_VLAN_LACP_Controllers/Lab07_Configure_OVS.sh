#!/usr/bin/env bash
# Run INSIDE either disposable OVS appliance after removing unused sample bridges.
set -euo pipefail
mode=${1:-trunk}
case "$mode" in trunk|bond) ;; *) echo 'Use trunk or bond' >&2; exit 2;; esac
ovs-vsctl --may-exist add-br my-br
ovs-vsctl set Bridge my-br protocols=OpenFlow13 stp_enable=true
ovs-vsctl set-fail-mode my-br secure
ovs-vsctl --may-exist add-port my-br eth1
ovs-vsctl --may-exist add-port my-br eth2
ovs-vsctl set Port eth1 vlan_mode=access tag=10
ovs-vsctl set Port eth2 vlan_mode=access tag=20
if [[ "$mode" == trunk ]]; then
  ovs-vsctl --if-exists del-port my-br bond1
  ovs-vsctl --may-exist add-port my-br eth11
  ovs-vsctl set Port eth11 vlan_mode=trunk trunks=10,20
else
  ovs-vsctl --if-exists del-port my-br eth11
  ovs-vsctl --if-exists del-port my-br eth12
  ovs-vsctl --may-exist add-bond my-br bond1 eth11 eth12
  ovs-vsctl set Port bond1 vlan_mode=trunk trunks=10,20 lacp=active bond_mode=balance-tcp
fi
for port in eth1 eth2 eth11; do ip link set "$port" up; done
if [[ "$mode" == bond ]]; then ip link set eth12 up; fi
ip link set my-br up
ovs-ofctl -O OpenFlow13 add-flow my-br 'cookie=0x700,priority=0,actions=NORMAL'
