#!/usr/bin/env bash
# Run INSIDE the dedicated inline firewall OVS: eth1 User1, eth2 Branch1.
set -euo pipefail
bridge=project-br
for number in 1 2; do
  [[ $(ovs-vsctl get Interface "eth$number" ofport) == "$number" ]] || exit 1
done
# Replace only this disposable firewall's pipeline, never a branch/router bridge.
ovs-ofctl -O OpenFlow13 del-flows "$bridge"
cat > /tmp/project-firewall.flows <<'EOF'
cookie=0xbf00,table=0,priority=500,arp,actions=NORMAL
cookie=0xbf00,table=0,priority=400,ip,ct_state=-trk,actions=ct(table=1,zone=11)
cookie=0xbf00,table=0,priority=0,actions=drop
cookie=0xbf00,table=1,priority=600,ip,ct_state=+trk+inv,actions=drop
cookie=0xbf00,table=1,priority=500,ip,ct_state=+trk+est,actions=NORMAL
cookie=0xbf00,table=1,priority=500,ip,ct_state=+trk+rel,actions=NORMAL
cookie=0xbf00,table=1,priority=400,in_port=1,ip,ct_state=+trk+new,actions=ct(commit,zone=11),NORMAL
cookie=0xbf00,table=1,priority=350,in_port=2,icmp,nw_src=192.168.123.3,nw_dst=192.168.123.1,ct_state=+trk+new,actions=drop
cookie=0xbf00,table=1,priority=350,in_port=2,udp,nw_src=192.168.123.3,nw_dst=192.168.123.1,ct_state=+trk+new,actions=drop
cookie=0xbf00,table=1,priority=300,in_port=2,tcp,nw_src=192.168.123.2,nw_dst=192.168.123.1,ct_state=+trk+new,actions=ct(commit,zone=11),NORMAL
cookie=0xbf00,table=1,priority=300,in_port=2,icmp,nw_src=192.168.123.2,nw_dst=192.168.123.1,ct_state=+trk+new,actions=ct(commit,zone=11),NORMAL
cookie=0xbf00,table=1,priority=250,in_port=2,ip,nw_src=192.168.123.3,nw_dst=192.168.123.1,ct_state=+trk+new,actions=ct(commit,zone=11),NORMAL
cookie=0xbf00,table=1,priority=0,actions=drop
EOF
ovs-ofctl -O OpenFlow13 add-flows "$bridge" /tmp/project-firewall.flows
