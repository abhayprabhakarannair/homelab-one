#!/usr/bin/env bash
# One-time root setup. Run: sudo ./install-root.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }

REPO="/home/abhay/homelab-one"
loginctl enable-linger abhay
ln -sfn "$REPO/caddy/Caddyfile" /etc/caddy/Caddyfile
systemctl enable --now caddy
systemctl reload caddy
echo "root setup done"
