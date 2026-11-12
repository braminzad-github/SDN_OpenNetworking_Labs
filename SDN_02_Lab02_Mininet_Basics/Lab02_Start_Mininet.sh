#!/bin/bash
set -euo pipefail

lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$lab_dir"

for tool in mn ovs-vsctl ss; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Required tool is missing: %s. Complete SDN_00_LabSetup first.\n' "$tool" >&2
    exit 1
  fi
done

if ! command -v ovs-testcontroller >/dev/null 2>&1 \
   && ! command -v ovs-controller >/dev/null 2>&1 \
   && ! command -v test-controller >/dev/null 2>&1; then
  printf 'No OVS test-controller binary found. Complete SDN_00_LabSetup first.\n' >&2
  exit 1
fi

if ss -ltnH 'sport = :16633' | grep -q .; then
  printf 'TCP port 16633 is already in use. Identify its owner before starting another lab.\n' >&2
  exit 1
fi

sudo -v
sudo ovs-vsctl show >/dev/null
mkdir -p config_backup

exec sudo mn --mac --switch ovs,protocols=OpenFlow10 \
  --controller ovsc,ip=127.0.0.1,port=16633 "$@"
