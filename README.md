# dcfg-tsb

Dotconfig Tracked Sub-folders - A modular, cross-platform dotfiles repository supporting multiple operating systems and shells.

## Overview

This repository tracks configuration files that should be version-controlled and portable across systems. It uses a layered configuration system to handle differences between platforms, roles, and individual hosts.

**Design Principles:**
- Single repo for all hosts and platforms
- Layered configuration: global → platform → role → host
- POSIX shell compatibility (bash/zsh share modules)
- Extensible for fish/PowerShell when needed
- Credentials and secrets are **never** tracked

## Platform Support

| Platform | Init System | Status |
|----------|-------------|--------|
| Linux (Debian, Ubuntu, Fedora, Arch, etc.) | systemd | Full |
| macOS (Intel & ARM) | launchd | Full |
| FreeBSD | rc.d | Full |
| Windows (WSL) | systemd | Full (treated as Linux) |
| Windows (native) | - | PowerShell only (future) |

## Shell Support

| Shell | Status | Notes |
|-------|--------|-------|
| bash | Implemented | POSIX shared modules |
| zsh | Implemented | POSIX shared modules + zsh extras |
| fish | Planned | Separate syntax, future implementation |
| PowerShell | Planned | Windows-only, future implementation |

## Directory Structure

```
~/.dcfg-tsb/
├── config/
│   ├── rc.conf                     # Global defaults (all hosts)
│   ├── platforms/
│   │   ├── linux.conf              # Linux-wide settings
│   │   ├── darwin.conf             # macOS settings
│   │   └── freebsd.conf            # FreeBSD settings
│   ├── roles/
│   │   ├── client.conf             # Workstation overrides
│   │   └── server.conf             # Server overrides
│   └── hosts/
│       ├── nyogtha.conf            # Debian 13 server
│       └── ...
│
├── services/                       # Platform-specific service managers
│   ├── systemd/                    # Linux
│   │   ├── common/                 # Shared across Linux hosts
│   │   └── hosts/
│   │       └── nyogtha/            # Host-specific services
│   ├── launchd/                    # macOS
│   │   ├── common/
│   │   └── hosts/
│   └── rc.d/                       # FreeBSD
│       ├── common/
│       └── hosts/
│
├── shell/
│   ├── posix/                      # Shared bash/zsh code
│   │   ├── aliases.sh              # Common aliases
│   │   ├── functions.sh            # Utility functions
│   │   ├── git.sh                  # Git helpers
│   │   └── platforms/              # Platform-specific POSIX code
│   │       ├── linux.sh
│   │       └── darwin.sh
│   │
│   ├── bash/
│   │   ├── .bashrc                 # Main bash config (sources posix/)
│   │   ├── .bash_profile
│   │   ├── .profile
│   │   └── modules/                # Bash-only features
│   │
│   ├── zsh/
│   │   ├── .zshrc                  # Main zsh config (sources posix/)
│   │   ├── .zshenv
│   │   ├── .zprofile
│   │   └── modules/                # Zsh-specific (completions, plugins)
│   │
│   ├── fish/                       # Future: Fish shell
│   │   └── .gitkeep
│   │
│   └── powershell/                 # Future: PowerShell (Windows)
│       └── .gitkeep
│
├── apps/                           # Application configurations
│   ├── ghostty/
│   │   └── config
│   ├── git/
│   │   ├── config
│   │   └── ignore
│   ├── ssh/
│   │   └── config
│   ├── Yubico/
│   │   └── u2f_keys
│   └── rclone/
│       └── rclone.conf.template    # Template only, NOT actual config
│
├── envs/                           # Environment variable fragments
│   ├── 000_xdg.env                 # XDG base directories
│   └── ...
│
├── lib/
│   ├── runtime.sh                  # Config loading (POSIX)
│   └── detect-platform.sh          # Platform/arch detection
│
└── scripts/
    ├── setup-symlinks.sh           # Creates symlinks (POSIX)
    ├── doctor.sh                   # Environment validation
    └── install.sh                  # First-time setup
```

## Configuration Layering

Settings are loaded in order (later overrides earlier):

```
1. config/rc.conf                   # Global defaults
2. config/platforms/<platform>.conf # OS-specific (linux, darwin, freebsd)
3. config/roles/<role>.conf         # Client vs server
4. config/hosts/<hostname>.conf     # Per-machine
5. Environment variables            # Runtime overrides
```

### Example: Module Resolution

```bash
# rc.conf (global)
module.ssh_forward="auto"

# platforms/linux.conf
# (not set, inherits auto)

# roles/server.conf
module.ssh_forward="on"

# hosts/nygotha.conf
# (not set, inherits from role)

# Result: ssh_forward is "on" for nygotha
```

## Hosts

| Hostname | Platform | Role | Notes |
|----------|----------|------|-------|
| nygotha | Linux (Debian 13) | server | Primary server |
| zadok | Linux (Ubuntu) | server | Reference system |

## What Gets Tracked

### Always Track
- Shell configurations (bash, zsh)
- Application configs (ghostty, git, ssh client config)
- Service definitions (systemd units, launchd plists)
- YubiKey FIDO2 registrations
- Environment setup scripts

### Never Track
- `rclone/rclone.conf` - Contains OAuth tokens
- `~/.ssh/id_*` - Private keys
- `dconf/` - GNOME binary database
- `gtk-*/`, `pulse/` - Auto-generated desktop configs
- Any file containing passwords, API keys, or tokens

## Usage

### Initial Setup (New Host)

```bash
# 1. Clone the repository
git clone <repo-url> ~/.dcfg-tsb

# 2. Create host config
cat > ~/.dcfg-tsb/config/hosts/$(hostname).conf << 'EOF'
platform="linux"  # or "darwin", "freebsd"
role="server"     # or "client"
EOF

# 3. Run setup
~/.dcfg-tsb/scripts/setup-symlinks.sh

# 4. Validate
~/.dcfg-tsb/scripts/doctor.sh
```

### Adding a New Platform Service

For Linux (systemd):
```bash
# Common service (all Linux hosts)
cp myservice.service ~/.dcfg-tsb/services/systemd/common/

# Host-specific service
cp myservice.service ~/.dcfg-tsb/services/systemd/hosts/$(hostname)/
```

For macOS (launchd):
```bash
cp com.user.myservice.plist ~/.dcfg-tsb/services/launchd/common/
```

### Symlink Strategy

The setup script creates symlinks based on detected platform:

```
# Shell configs (all platforms)
~/.bashrc           → ~/.dcfg-tsb/shell/bash/.bashrc
~/.zshrc            → ~/.dcfg-tsb/shell/zsh/.zshrc

# App configs (all platforms)
~/.config/ghostty/  → ~/.dcfg-tsb/apps/ghostty/
~/.config/git/      → ~/.dcfg-tsb/apps/git/
~/.gitconfig        → ~/.dcfg-tsb/apps/git/config

# Services (platform-specific)
# Linux:
~/.config/systemd/user/<service> → ~/.dcfg-tsb/services/systemd/...
# macOS:
~/Library/LaunchAgents/<plist>   → ~/.dcfg-tsb/services/launchd/...
```

## POSIX Shell Module System

bash and zsh share common code via `shell/posix/`:

```bash
# In shell/bash/.bashrc or shell/zsh/.zshrc:
DCFG_ROOT="${DCFG_ROOT:-$HOME/.dcfg-tsb}"

# Source shared POSIX modules
for module in "$DCFG_ROOT/shell/posix"/*.sh; do
    [ -r "$module" ] && source "$module"
done

# Source platform-specific module
platform=$(uname -s | tr '[:upper:]' '[:lower:]')
[ -r "$DCFG_ROOT/shell/posix/platforms/$platform.sh" ] && \
    source "$DCFG_ROOT/shell/posix/platforms/$platform.sh"
```

## Future: Fish & PowerShell

The structure supports adding fish and PowerShell later:

- **Fish**: Add `shell/fish/config.fish` and `shell/fish/functions/`
- **PowerShell**: Add `shell/powershell/profile.ps1` and `shell/powershell/modules/`

These shells have incompatible syntax, so modules must be rewritten (not shared with POSIX).

## Relationship to dotconfig-collection

This repo is inspired by `~/src/dotconfig-collection` (zadok system) but redesigned for:
- Explicit cross-platform support (services/ directory)
- Multi-shell extensibility (shell/ with posix/ shared code)
- Cleaner separation of apps vs shell vs services

Configs can be ported from dotconfig-collection as needed.

## License

Private configuration repository.
