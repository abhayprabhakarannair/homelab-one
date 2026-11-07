#!/usr/bin/env bash
# Idempotent setup for homelab-one. Run as abhay, not root.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo "run as abhay, not root"; exit 1; }

REPO="$(cd "$(dirname "$0")" && pwd)"
UNIT_DIR="$HOME/.config/systemd/user"
QUADLET_DIR="$HOME/.config/containers/systemd"
REMOTE="homelab-storage-one-combined:"

# 1. Preflight: fail loudly if a prerequisite is missing
for cmd in podman rclone fusermount3 caddy tailscale; do
  command -v "$cmd" >/dev/null || { echo "missing: $cmd"; exit 1; }
done
[[ -f "$HOME/.config/rclone/rclone.conf" ]] || { echo "missing rclone.conf"; exit 1; }
[[ -f "$HOME/.ssh/homelab" ]] || { echo "missing storage box key"; exit 1; }
rclone listremotes --config "$HOME/.config/rclone/rclone.conf" | grep -qx "$REMOTE" \
  || { echo "remote $REMOTE not in rclone.conf"; exit 1; }

# 2. Persistent user services (start at boot without login)
sudo loginctl enable-linger "$USER"

# 3. Directories
sudo install -d -o "$USER" -g "$USER" /mnt/homelab
install -d "$REPO/jellyfin/data/config" "$REPO/jellyfin/data/cache"

# 4. Link units (repo stays the source of truth)
install -d "$UNIT_DIR" "$QUADLET_DIR"
ln -sfn "$REPO/rclone/rclone-homelab.service" "$UNIT_DIR/rclone-homelab.service"
ln -sfn "$REPO/quadlet/jellyfin.container" "$QUADLET_DIR/jellyfin.container"

# 5. Start services as abhay
systemctl --user daemon-reload
systemctl --user enable --now rclone-homelab.service
for _ in $(seq 1 15); do mountpoint -q /mnt/homelab && break; sleep 1; done
mountpoint -q /mnt/homelab || { echo "mount failed: journalctl --user -u rclone-homelab"; exit 1; }
systemctl --user start jellyfin.service

# 6. Caddy (system service, needs root for /etc)
sudo ln -sfn "$REPO/caddy/Caddyfile" /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
sudo systemctl reload caddy

echo "done. Check: https://jellyfin.iamabhay.fyi"
