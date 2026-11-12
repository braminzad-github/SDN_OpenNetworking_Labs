#!/usr/bin/env bash
# Optional stateless ACL baseline. eth1=User1; eth2=Branch1.
# Use Project_Firewall.sh for stateful reply handling in the main guide.
set -euo pipefail
bridge=project-br
for number in 1 2; do
  [[ $(ovs-vsctl get Interface "eth$number" ofport) == "$number" ]] || exit 1
done
ovs-ofctl -O OpenFlow13 del-flows "$bridge"
cat > /tmp/project-firewall-acl.flows <<'EOF'
cookie=0xbf10,priority=1000,in_port=1,actions=NORMAL
cookie=0xbf10,priority=900,arp,actions=NORMAL
cookie=0xbf10,priority=400,in_port=2,icmp,nw_src=192.168.123.3,nw_dst=192.168.123.1,actions=drop
cookie=0xbf10,priority=400,in_port=2,udp,nw_src=192.168.123.3,nw_dst=192.168.123.1,actions=drop
cookie=0xbf10,priority=300,in_port=2,ip,nw_src=192.168.123.3,nw_dst=192.168.123.1,actions=NORMAL
cookie=0xbf10,priority=400,in_port=2,tcp,nw_src=192.168.123.2,nw_dst=192.168.123.1,actions=NORMAL
cookie=0xbf10,priority=400,in_port=2,icmp,nw_src=192.168.123.2,nw_dst=192.168.123.1,actions=NORMAL
cookie=0xbf10,priority=0,actions=drop
EOF
ovs-ofctl -O OpenFlow13 add-flows "$bridge" /tmp/project-firewall-acl.flows
