# Rclone Quick Reference

For comprehensive setup, see: `~/mnt/dotconfig/RCLONE-SETUP.md`

## Current Mounts (nyogtha)

| Remote | Type | Mount | Service |
|--------|------|-------|---------|
| dotconfig | Dropbox (app-scoped) | `~/mnt/dotconfig` | `rclone-dotconfig` |
| dotconfig-crypt | Encrypted | `~/mnt/dotconfig-secure` | `rclone-dotconfig-crypt` |
| nyogtha-sys | Dropbox (app-scoped) | `~/mnt/nyogtha-sys` | `rclone-nyogtha-sys` |
| nyogtha-crypt | Encrypted | `~/mnt/nyogtha-secure` | `rclone-nyogtha-crypt` |
| bananapeel | Dropbox (app-scoped) | `~/mnt/bananapeel` | `rclone-bananapeel` |

## Common Commands

### Service Management

```bash
# Status
systemctl --user status rclone-dotconfig-crypt

# Start/Stop
systemctl --user start rclone-dotconfig-crypt
systemctl --user stop rclone-dotconfig-crypt

# Restart (after config changes)
systemctl --user daemon-reload
systemctl --user restart rclone-dotconfig-crypt

# View logs
journalctl --user -u rclone-dotconfig-crypt -f
```

### Mount Verification

```bash
# Check all mounts
mount | grep rclone

# List mount contents
ls ~/mnt/dotconfig-secure/

# Test write access
echo "test" > ~/mnt/dotconfig-secure/test.txt && rm ~/mnt/dotconfig-secure/test.txt
```

### Troubleshooting

```bash
# Unmount stale mount
fusermount -u ~/mnt/dotconfig-secure

# Test remote directly
rclone lsd dotconfig-crypt:

# Check remote config (no secrets shown)
rclone config show dotconfig-crypt | grep -E '^(type|remote)'
```

## Adding New Encrypted Remote

```bash
rclone config
# n) New remote
# name: <name>-crypt
# type: crypt
# remote: <base-remote>:encrypted
# filename encryption: standard
# directory encryption: true
# password: <strong password>
# salt: <different password>
```

Then create service file in `~/.dcfg-tsb/services/systemd/common/` or `hosts/<hostname>/`.

## Service File Template

```ini
[Unit]
Description=Rclone mount for <name>
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount <remote>: %h/mnt/<mountpoint> \
    --vfs-cache-mode full \
    --vfs-cache-max-age 24h \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 256M \
    --dir-cache-time 72h \
    --poll-interval 15s \
    --attr-timeout 1s \
    --allow-other \
    --log-level INFO
ExecStop=/bin/fusermount -uz %h/mnt/<mountpoint>
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```
