#!/usr/bin/env bash
set -euo pipefail
# Usage: bash Lab09_Open_Terminals.sh name:port [name:port ...]
# Copy the actual TCP console ports from GNS3, not the data interface numbers.
session="sdn09"
if tmux has-session -t "$session" 2>/dev/null; then
  tmux set -g mouse on
  exec tmux attach -t "$session"
fi
if (( $# == 0 )); then
  echo 'Provide each GNS3 console as node-name:TCP-port' >&2
  exit 2
fi
command -v telnet >/dev/null
commands=()
for spec in "$@"; do
  name=${spec%:*}; port=${spec##*:}
  if [[ ! "$name" =~ ^[A-Za-z0-9_-]+$ || ! "$port" =~ ^[0-9]{1,5}$ ]]; then
    echo "Invalid console specification: $spec" >&2; exit 2
  fi
  number=$((10#$port))
  if (( number < 1 || number > 65535 )); then exit 2; fi
  commands+=("printf '\\nConsole: %s\\n' '$name'; telnet 127.0.0.1 $number; exec bash")
done
tmux new-session -d -s "$session" -n lab "${commands[0]}"
for command in "${commands[@]:1}"; do
  tmux split-window -t "$session:lab" "$command"
  tmux select-layout -t "$session:lab" tiled
done
tmux split-window -t "$session:lab" 'bash'
tmux select-layout -t "$session:lab" tiled
tmux set -g mouse on
exec tmux attach -t "$session"
