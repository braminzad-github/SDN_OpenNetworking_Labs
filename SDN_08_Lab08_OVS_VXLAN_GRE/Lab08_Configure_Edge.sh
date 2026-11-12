#!/usr/bin/env bash
# Run INSIDE an edge OVS appliance: bash ... edge1 vxlan|gre
set -euo pipefail
role=${1:?Use edge1 or edge2}; tunnel=${2:-vxlan}
case "$role" in
  edge1) local_ip=172.16.10.2; remote_ip=172.16.20.2; gateway=172.16.10.1; dpid=0000000000000001 ;;
  edge2) local_ip=172.16.20.2; remote_ip=172.16.10.2; gateway=172.16.20.1; dpid=0000000000000002 ;;
  *) exit 2;;
esac
case "$tunnel" in vxlan) vlan=10;; gre) vlan=20;; *) exit 2;; esac
ovs-vsctl --may-exist add-br my-br
ovs-vsctl set Bridge my-br protocols=OpenFlow13 other-config:datapath-id="$dpid"
ovs-vsctl set-fail-mode my-br secure
ovs-vsctl --may-exist add-port my-br eth1
ovs-vsctl set Port eth1 vlan_mode=access tag="$vlan"
# eth11 is a routed Linux transport interface; it must not join my-br.
if ovs-vsctl port-to-br eth11 >/dev/null 2>&1; then
  echo 'eth11 belongs to a bridge; inspect and remove that assignment first' >&2; exit 1
fi
ip addr replace "$local_ip/24" dev eth11
ip link set eth11 up
ip link set eth1 up
ip route replace "$remote_ip/32" via "$gateway" dev eth11
ovs-vsctl --if-exists del-port my-br overlay
ovs-vsctl add-port my-br overlay -- set Port overlay vlan_mode=access tag="$vlan" \
  -- set Interface overlay type="$tunnel" options:local_ip="$local_ip" \
  options:remote_ip="$remote_ip" options:key="$vlan"
if [[ "$tunnel" == vxlan ]]; then
  ovs-vsctl set Interface overlay options:dst_port=4789
fi
ovs-ofctl -O OpenFlow13 add-flow my-br 'cookie=0x800,priority=0,actions=NORMAL'
