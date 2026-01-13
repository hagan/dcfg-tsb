# Setup Guide

Quick setup for a new host.

## Prerequisites

- Git
- Bash or Zsh
- rclone (for cloud sync)

## Initial Setup

### 1. Clone Repository

```bash
git clone <repo-url> ~/.dcfg-tsb
```

### 2. Create Host Config

```bash
cat > ~/.dcfg-tsb/config/hosts/$(hostname).conf << 'EOF'
# Adjust platform and role for your system
platform="linux"    # linux, darwin, freebsd
role="server"       # server, client
EOF
```

### 3. Backup Existing Configs

The setup script won't overwrite existing files, but backup first:

```bash
# Backup shell configs
[ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.backup
[ -f ~/.profile ] && cp ~/.profile ~/.profile.backup

# Backup app configs that will be symlinked
[ -d ~/.config/ghostty ] && mv ~/.config/ghostty ~/.config/ghostty.backup
```

### 4. Run Setup

```bash
# Remove originals to allow symlinks
rm -f ~/.bashrc ~/.profile

# Create symlinks
~/.dcfg-tsb/scripts/setup-symlinks.sh

# Validate
~/.dcfg-tsb/scripts/doctor.sh
```

### 5. Reload Shell

```bash
source ~/.bashrc
```

## Rclone Mounts (Optional)

If using cloud-synced sensitive files:

### Configure Rclone Remotes

```bash
rclone config
# Create remotes: dotconfig, dotconfig-crypt, etc.
```

### Start Mount Services

```bash
# Create mount points
mkdir -p ~/mnt/dotconfig ~/mnt/dotconfig-secure

# Enable and start services
systemctl --user daemon-reload
systemctl --user enable --now rclone-dotconfig
systemctl --user enable --now rclone-dotconfig-crypt
```

### Restore Sensitive Files

```bash
dcfg-sync pull
```

## Verification

```bash
# Run doctor
dcfg-doctor

# Check symlinks
ls -la ~/.bashrc ~/.config/ghostty

# Test platform detection
eval "$(~/.dcfg-tsb/scripts/detect-platform.sh)"
echo "Platform: $CONFIG_PLATFORM, Role: $CONFIG_ROLE, Host: $CONFIG_HOST"
```

## Troubleshooting

### Symlink exists but wrong target

```bash
# Remove and recreate
rm ~/.bashrc
~/.dcfg-tsb/scripts/setup-symlinks.sh
```

### Mount not working

```bash
# Check service status
systemctl --user status rclone-dotconfig-crypt

# Check logs
journalctl --user -u rclone-dotconfig-crypt -f
```

### Shell config not loading

```bash
# Source manually to see errors
source ~/.dcfg-tsb/shell/bash/.bashrc
```
