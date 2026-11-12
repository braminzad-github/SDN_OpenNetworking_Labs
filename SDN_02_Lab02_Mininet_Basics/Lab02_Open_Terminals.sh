#!/bin/bash
set -euo pipefail

if [[ -n "${TMUX:-}" ]]; then
  printf 'Run this launcher from an Ubuntu terminal outside tmux.\n' >&2
  exit 1
fi

session="sdn-lab02"
lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if tmux has-session -t "$session" 2>/dev/null; then
  tmux set -g mouse on
  exec tmux attach-session -t "$session"
fi

tmux new-session -d -s "$session" -n lab -c "$lab_dir" \
  'bash ./Lab02_Start_Mininet.sh --topo minimal'
tmux split-window -t "$session:lab" -c "$lab_dir" 'bash'
tmux select-layout -t "$session:lab" tiled
tmux split-window -t "$session:lab" -c "$lab_dir" 'bash'
tmux select-layout -t "$session:lab" tiled
tmux set -g mouse on
exec tmux attach-session -t "$session"
