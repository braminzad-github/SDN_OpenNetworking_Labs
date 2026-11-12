#!/usr/bin/env bash
# Run INSIDE the inline translator: eth1 Server2, eth2 Branch2.
set -euo pipefail
bridge=project-br
for number in 1 2; do
  [[ $(ovs-vsctl get Interface "eth$number" ofport) == "$number" ]] || exit 1
done
for protocol in udp tcp; do
  ovs-ofctl -O OpenFlow13 add-flow "$bridge" \
    "cookie=0xbd00,priority=300,in_port=1,$protocol,nw_src=172.16.123.2,nw_dst=172.16.123.3,tp_dst=300,actions=mod_tp_dst:500,NORMAL"
  ovs-ofctl -O OpenFlow13 add-flow "$bridge" \
    "cookie=0xbd00,priority=300,in_port=2,$protocol,nw_src=172.16.123.3,nw_dst=172.16.123.2,tp_src=500,actions=mod_tp_src:300,NORMAL"
done
