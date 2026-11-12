#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
exec sudo mn --custom Lab03_Topologies.py --topo "${1:-singlelab,3}" --mac \
  --switch ovs,protocols=OpenFlow10 \
  --controller ovsc,ip=127.0.0.1,port=16633
