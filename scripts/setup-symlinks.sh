#!/usr/bin/env sh
# Create symlinks from standard locations to ~/.dcfg-tsb
# Written in POSIX sh for compatibility with all platforms

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
NC="\033[0m"

# Detect platform
detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    Linux) echo "linux" ;;
    FreeBSD) echo "freebsd" ;;
    *) echo "unknown" ;;
  esac
}

# Get hostname (short form)
get_hostname() {
  hostname | tr '[:upper:]' '[:lower:]' | cut -d. -f1
}

PLATFORM=$(detect_platform)
HOSTNAME=$(get_hostname)

printf '%b=== dcfg-tsb Symlink Setup ===%b\n' "$CYAN" "$NC"
printf 'Platform: %s\n' "$PLATFORM"
printf 'Hostname: %s\n' "$HOSTNAME"
printf 'Repo root: %s\n\n' "$REPO_ROOT"

create_symlink() {
  src=$1
  dest=$2

  if [ -L "$dest" ]; then
    current=$(readlink "$dest")
    if [ "$current" = "$src" ]; then
      printf '%b[ok]%b %s\n' "$GREEN" "$NC" "$dest"
    else
      printf '%b[warn]%b %s -> %s (expected %s)\n' "$YELLOW" "$NC" "$dest" "$current" "$src"
    fi
  elif [ -e "$dest" ]; then
    printf '%b[skip]%b %s exists (not a symlink)\n' "$RED" "$NC" "$dest"
  else
    # Create parent directory if needed
    dest_dir=$(dirname "$dest")
    if [ ! -d "$dest_dir" ]; then
      mkdir -p "$dest_dir"
    fi
    ln -sf "$src" "$dest"
    printf '%b[new]%b %s -> %s\n' "$GREEN" "$NC" "$dest" "$src"
  fi
}

# ============================================================
# Shell Configuration Symlinks
# ============================================================
printf '%b--- Shell Configs ---%b\n' "$CYAN" "$NC"

# Bash
if [ -f "${REPO_ROOT}/shell/bash/.bashrc" ]; then
  create_symlink "${REPO_ROOT}/shell/bash/.bashrc" "$HOME/.bashrc"
fi
if [ -f "${REPO_ROOT}/shell/bash/.bash_profile" ]; then
  create_symlink "${REPO_ROOT}/shell/bash/.bash_profile" "$HOME/.bash_profile"
fi
if [ -f "${REPO_ROOT}/shell/bash/.profile" ]; then
  create_symlink "${REPO_ROOT}/shell/bash/.profile" "$HOME/.profile"
fi

# ZSH
if [ -f "${REPO_ROOT}/shell/zsh/.zshrc" ]; then
  create_symlink "${REPO_ROOT}/shell/zsh/.zshrc" "$HOME/.zshrc"
fi
if [ -f "${REPO_ROOT}/shell/zsh/.zshenv" ]; then
  create_symlink "${REPO_ROOT}/shell/zsh/.zshenv" "$HOME/.zshenv"
fi
if [ -f "${REPO_ROOT}/shell/zsh/.zprofile" ]; then
  create_symlink "${REPO_ROOT}/shell/zsh/.zprofile" "$HOME/.zprofile"
fi

# ============================================================
# Application Config Symlinks
# ============================================================
printf '\n%b--- App Configs ---%b\n' "$CYAN" "$NC"

# Ghostty
if [ -d "${REPO_ROOT}/apps/ghostty" ]; then
  create_symlink "${REPO_ROOT}/apps/ghostty" "$HOME/.config/ghostty"
fi

# Git
if [ -d "${REPO_ROOT}/apps/git" ]; then
  create_symlink "${REPO_ROOT}/apps/git" "$HOME/.config/git"
fi
if [ -f "${REPO_ROOT}/apps/git/config" ]; then
  create_symlink "${REPO_ROOT}/apps/git/config" "$HOME/.gitconfig"
fi

# SSH (config only, not keys)
if [ -f "${REPO_ROOT}/apps/ssh/config" ]; then
  create_symlink "${REPO_ROOT}/apps/ssh/config" "$HOME/.ssh/config"
fi

# Yubico
if [ -d "${REPO_ROOT}/apps/Yubico" ]; then
  create_symlink "${REPO_ROOT}/apps/Yubico" "$HOME/.config/Yubico"
fi

# ============================================================
# Platform-Specific Service Symlinks
# ============================================================
printf '\n%b--- Services (%s) ---%b\n' "$CYAN" "$PLATFORM" "$NC"

case "$PLATFORM" in
  linux)
    # systemd user services
    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_USER_DIR"

    # Common services (all Linux hosts)
    if [ -d "${REPO_ROOT}/services/systemd/common" ]; then
      for service in "${REPO_ROOT}/services/systemd/common"/*.service; do
        [ -f "$service" ] || continue
        name=$(basename "$service")
        create_symlink "$service" "${SYSTEMD_USER_DIR}/${name}"
      done
    fi

    # Host-specific services
    HOST_SERVICES="${REPO_ROOT}/services/systemd/hosts/${HOSTNAME}"
    if [ -d "$HOST_SERVICES" ]; then
      for service in "${HOST_SERVICES}"/*.service; do
        [ -f "$service" ] || continue
        name=$(basename "$service")
        create_symlink "$service" "${SYSTEMD_USER_DIR}/${name}"
      done
    fi
    ;;

  darwin)
    # launchd user agents
    LAUNCHD_DIR="$HOME/Library/LaunchAgents"
    mkdir -p "$LAUNCHD_DIR"

    # Common agents (all macOS hosts)
    if [ -d "${REPO_ROOT}/services/launchd/common" ]; then
      for plist in "${REPO_ROOT}/services/launchd/common"/*.plist; do
        [ -f "$plist" ] || continue
        name=$(basename "$plist")
        create_symlink "$plist" "${LAUNCHD_DIR}/${name}"
      done
    fi

    # Host-specific agents
    HOST_AGENTS="${REPO_ROOT}/services/launchd/hosts/${HOSTNAME}"
    if [ -d "$HOST_AGENTS" ]; then
      for plist in "${HOST_AGENTS}"/*.plist; do
        [ -f "$plist" ] || continue
        name=$(basename "$plist")
        create_symlink "$plist" "${LAUNCHD_DIR}/${name}"
      done
    fi
    ;;

  freebsd)
    printf '  (No user-level rc.d services configured)\n'
    ;;

  *)
    printf '  (Unknown platform, skipping services)\n'
    ;;
esac

# ============================================================
# Summary
# ============================================================
printf '\n%b=== Setup Complete ===%b\n' "$GREEN" "$NC"
printf 'Run the following to reload shell config:\n'
printf '  source ~/.bashrc   # for bash\n'
printf '  source ~/.zshrc    # for zsh\n'

if [ "$PLATFORM" = "linux" ]; then
  printf '\nTo enable systemd services:\n'
  printf '  systemctl --user daemon-reload\n'
  printf '  systemctl --user enable --now <service-name>\n'
fi
