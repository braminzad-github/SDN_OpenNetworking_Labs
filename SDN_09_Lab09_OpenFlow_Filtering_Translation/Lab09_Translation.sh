#!/usr/bin/env bash
# Run inside Lab09 OVS appliance only. Numeric port mapping must be checked first.
set -euo pipefail
mode=${1:-install}
if [[ "$mode" == remove ]]; then
  ovs-ofctl -O OpenFlow13 del-flows my-br 'cookie=0x9300/-1'
  exit
fi
[[ "$mode" == install ]] || exit 2
for spec in eth1:1 eth2:2 eth3:3; do
  name=${spec%:*}; expected=${spec##*:}
  actual=$(ovs-vsctl get Interface "$name" ofport)
  [[ "$actual" == "$expected" ]] || { echo "Incorrect ofport for $name: $actual" >&2; exit 1; }
done
for protocol in tcp udp; do
  ovs-ofctl -O OpenFlow13 add-flow my-br \
    "cookie=0x9300,priority=300,in_port=1,$protocol,nw_src=172.16.10.1,nw_dst=172.16.10.3,tp_dst=1000,actions=mod_tp_dst:3000,NORMAL"
  ovs-ofctl -O OpenFlow13 add-flow my-br \
    "cookie=0x9300,priority=300,in_port=3,$protocol,nw_src=172.16.10.3,nw_dst=172.16.10.1,tp_src=3000,actions=mod_tp_src:1000,NORMAL"
done
