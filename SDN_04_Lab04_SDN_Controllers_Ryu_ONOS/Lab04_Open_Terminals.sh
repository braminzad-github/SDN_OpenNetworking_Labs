#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
session="sdn04"
if tmux has-session -t "$session" 2>/dev/null; then
  tmux set -g mouse on
  exec tmux attach -t "$session"
fi
tmux new-session -d -s "$session" -n lab bash
tmux split-window -t "$session:lab" bash
tmux select-layout -t "$session:lab" tiled
tmux split-window -t "$session:lab" bash
tmux select-layout -t "$session:lab" tiled
tmux split-window -t "$session:lab" bash
tmux select-layout -t "$session:lab" tiled
tmux set -g mouse on
tmux select-pane -t "$session:lab.0"
exec tmux attach -t "$session"
