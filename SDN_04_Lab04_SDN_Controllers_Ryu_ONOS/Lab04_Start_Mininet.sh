#!/usr/bin/env bash
set -euo pipefail
case "${1:-ryu}" in
  ryu) protocol=OpenFlow14 ;;
  onos) protocol=OpenFlow13 ;;
  *) echo 'Usage: bash Lab04_Start_Mininet.sh ryu|onos' >&2; exit 2 ;;
esac
exec sudo mn --topo "${2:-single,2}" --mac --ipbase 172.16.10.0/24 \
  --switch "ovs,protocols=$protocol" --controller remote,ip=127.0.0.1,port=6653
