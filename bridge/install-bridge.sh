#!/bin/sh
# Render bridge/seer-ai-bridge.service with this checkout's absolute path
# and install it as a user systemd unit. Refuses to overwrite an existing
# installed unit unless -f is passed.
set -eu

force=0
case "${1:-}" in
  -f) force=1 ;;
  "") ;;
  *) echo "usage: $0 [-f]" >&2; exit 1 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
unit_src="$script_dir/seer-ai-bridge.service"
unit_dest_dir="$HOME/.config/systemd/user"
unit_dest="$unit_dest_dir/seer-ai-bridge.service"

if [ ! -f "$unit_src" ]; then
  echo "error: $unit_src not found" >&2
  exit 1
fi

node_bin=$(command -v node) || { echo "error: node not found on PATH" >&2; exit 1; }

if [ -e "$unit_dest" ] && [ "$force" -ne 1 ]; then
  echo "error: $unit_dest already exists; pass -f to overwrite" >&2
  exit 1
fi

mkdir -p "$unit_dest_dir"

sed \
  -e "s#/absolute/path/to/srrs/bridge/seer-ai-bridge.mjs#$repo_dir/bridge/seer-ai-bridge.mjs#" \
  -e "s#/absolute/path/to/srrs#$repo_dir#" \
  -e "s#/usr/bin/env node#$node_bin#" \
  "$unit_src" > "$unit_dest"

systemctl --user daemon-reload

echo "Installed $unit_dest"
echo
echo "Next steps (not run automatically):"
echo "  systemctl --user enable --now seer-ai-bridge"
echo
echo "Before starting, create ~/.config/seer/ai-bridge.json (bridge secret,"
echo "MCP cookie config) and optionally ~/.config/seer/ai-bridge.env with"
echo "SEER_BRIDGE_SECRET=... and SEER_MCP_COOKIE=... for EnvironmentFile=."
