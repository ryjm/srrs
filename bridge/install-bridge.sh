#!/bin/sh
# Render bridge/seer-ai-bridge.service and bridge/seer-ai-bridge@.service
# with this checkout's absolute path and install them as user systemd
# units. Units already installed are kept unless -f is passed; missing
# ones are always installed.
set -eu

force=0
case "${1:-}" in
  -f) force=1 ;;
  "") ;;
  *) echo "usage: $0 [-f]" >&2; exit 1 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
unit_dest_dir="$HOME/.config/systemd/user"

node_bin=$(command -v node) || { echo "error: node not found on PATH" >&2; exit 1; }

for unit in seer-ai-bridge.service seer-ai-bridge@.service; do
  if [ ! -f "$script_dir/$unit" ]; then
    echo "error: $script_dir/$unit not found" >&2
    exit 1
  fi
done

mkdir -p "$unit_dest_dir"

for unit in seer-ai-bridge.service seer-ai-bridge@.service; do
  unit_dest="$unit_dest_dir/$unit"
  if [ -e "$unit_dest" ] && [ "$force" -ne 1 ]; then
    echo "Kept existing $unit_dest (pass -f to re-render it)"
    continue
  fi
  sed \
    -e "s#/absolute/path/to/srrs/bridge/seer-ai-bridge.mjs#$repo_dir/bridge/seer-ai-bridge.mjs#" \
    -e "s#/absolute/path/to/srrs#$repo_dir#" \
    -e "s#/usr/bin/env node#$node_bin#" \
    "$script_dir/$unit" > "$unit_dest"
  echo "Installed $unit_dest"
done

systemctl --user daemon-reload

echo
echo "Next steps (not run automatically):"
echo "  systemctl --user enable --now seer-ai-bridge          # ~/.config/seer/ai-bridge.json"
echo "  systemctl --user enable --now seer-ai-bridge@NAME     # ~/.config/seer/ai-bridge-NAME.json"
echo
echo "Each instance serves one ship. Before starting one, create its config"
echo "(mcpUrl, bridge secret, MCP cookie source) and optionally the matching"
echo ".env file with SEER_BRIDGE_SECRET=... and SEER_MCP_COOKIE=... for"
echo "EnvironmentFile=."
