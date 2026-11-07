# homelab

Single server: homelab-one (AlmaLinux, rootless Podman, user abhay).

## Run
    ~/homelab/install.sh

## Services
- rclone-homelab (user unit): Storage Box mounted read-only at /mnt/homelab
- jellyfin (Quadlet, rootless): 127.0.0.1:8096, media from /mnt/homelab/media
- caddy (system): jellyfin.iamabhay.fyi -> 127.0.0.1:8096

## Secrets (not in git)
- ~/.config/rclone/rclone.conf
- ~/.ssh/homelab

## Change things
Edit the file in this repo, then run install.sh again. Units are symlinked, so no copies drift.

## Debug
    systemctl --user status rclone-homelab jellyfin
    journalctl --user -u rclone-homelab -e
    journalctl --user -u jellyfin -e
    sudo journalctl -u caddy -e

## Fallback
If Jellyfin shows an empty library, the FUSE mount is not propagating into the rootless container. Only then consider running rclone as root.
