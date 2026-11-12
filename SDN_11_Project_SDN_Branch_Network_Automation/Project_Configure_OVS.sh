#!/usr/bin/env bash
# Run only INSIDE the named disposable GNS3 appliance.
set -euo pipefail
role=${1:?Use branch1|branch2|branch3|wan|firewall|translator}
phase=${2:-base}
server_tunnel=${3:-vxlan}
case "$server_tunnel" in vxlan|gre) ;; *) echo "Use vxlan or gre for the server tunnel" >&2; exit 2;; esac
bridge=project-br
ovs-vsctl --may-exist add-br "$bridge"
ovs-vsctl set Bridge "$bridge" protocols=OpenFlow13
ovs-vsctl set-fail-mode "$bridge" secure
add_port() {
  ovs-vsctl --may-exist add-port "$bridge" "$1"
  ip link set "$1" up
}
tunnel() {
  # name,type,local,remote,VLAN/VNI-or-GRE-key
  ovs-vsctl --may-exist add-port "$bridge" "$1"
  ovs-vsctl set Port "$1" vlan_mode=access tag="$5" other-config:stp-enable=false
  ovs-vsctl set Interface "$1" type="$2" options:local_ip="$3" options:remote_ip="$4" options:key="$5"
  if [[ "$2" == vxlan ]]; then ovs-vsctl set Interface "$1" options:dst_port=4789; fi
}
case "$role" in
  branch1|branch2|branch3)
    case "$role" in
      branch1) local_ip=10.1.1.1; gateway=10.1.1.2; dpid=0000000000000101;;
      branch2) local_ip=10.2.2.1; gateway=10.2.2.2; dpid=0000000000000102;;
      branch3) local_ip=10.3.3.1; gateway=10.3.3.2; dpid=0000000000000103;;
    esac
    ovs-vsctl set Bridge "$bridge" other-config:datapath-id="$dpid" stp_enable=true
    if ovs-vsctl port-to-br eth5 >/dev/null 2>&1; then
      echo 'Remove transport eth5 from any example bridge first' >&2; exit 1
    fi
    ip addr replace "$local_ip/24" dev eth5
    ip link set eth5 up
    ip route replace 10.0.0.0/8 via "$gateway" dev eth5
    add_port eth1
    ovs-vsctl set Port eth1 vlan_mode=access tag=10
    case "$role" in
      branch1)
        tunnel vxlan12 vxlan "$local_ip" 10.2.2.1 10
        tunnel gre13 gre "$local_ip" 10.3.3.1 10 ;;
      branch2) tunnel vxlan12 vxlan "$local_ip" 10.1.1.1 10 ;;
      branch3) tunnel gre13 gre "$local_ip" 10.1.1.1 10 ;;
    esac
    if [[ "$phase" == servers && "$role" != branch1 ]]; then
      add_port eth2
      ovs-vsctl set Port eth2 vlan_mode=access tag=20
      if [[ "$role" == branch2 ]]; then remote_ip=10.3.3.1; else remote_ip=10.2.2.1; fi
      # Replace the alternate mode on both peers when changing tunnel type.
      if [[ "$server_tunnel" == vxlan ]]; then
        ovs-vsctl --if-exists del-port "$bridge" gre23
        tunnel vxlan23 vxlan "$local_ip" "$remote_ip" 20
      else
        ovs-vsctl --if-exists del-port "$bridge" vxlan23
        tunnel gre23 gre "$local_ip" "$remote_ip" 20
      fi
    elif [[ "$phase" != base && "$phase" != servers ]]; then exit 2; fi
    ovs-ofctl -O OpenFlow13 add-flow "$bridge" 'cookie=0xb000,priority=0,actions=NORMAL'
    ovs-ofctl -O OpenFlow13 add-flow "$bridge" 'cookie=0xb000,priority=100,arp,actions=CONTROLLER:128,NORMAL'
    ovs-vsctl set-controller "$bridge" tcp:192.168.122.1:7777
    ;;
  wan)
    ovs-vsctl set Bridge "$bridge" other-config:datapath-id=0000000000000104 stp_enable=true
    for port in eth1 eth2 eth3; do add_port "$port"; done
    ovs-vsctl set-controller "$bridge" tcp:192.168.122.1:6653
    ;;
  firewall|translator)
    ovs-vsctl del-controller "$bridge"
    for number in 1 2; do
      add_port "eth$number"
      ovs-vsctl set Interface "eth$number" ofport_request="$number"
      actual=$(ovs-vsctl get Interface "eth$number" ofport)
      [[ "$actual" == "$number" ]] || { echo 'ofport mismatch' >&2; exit 1; }
    done
    # No VLAN tags here: both are inline devices on untagged access links.
    ovs-ofctl -O OpenFlow13 add-flow "$bridge" 'cookie=0xb000,priority=0,actions=NORMAL'
    ;;
  *) echo 'Unknown role' >&2; exit 2;;
esac
