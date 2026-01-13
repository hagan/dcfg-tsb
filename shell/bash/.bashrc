# ~/.bashrc - Bash configuration for dcfg-tsb
# Sources shared POSIX modules and platform-specific configs

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ============================================================
# dcfg-tsb Configuration Loading
# ============================================================
DCFG_ROOT="${DCFG_ROOT:-$HOME/.dcfg-tsb}"

# Load configuration layers and export CONFIG_* variables
if [ -x "${DCFG_ROOT}/scripts/detect-platform.sh" ]; then
    eval "$("${DCFG_ROOT}/scripts/detect-platform.sh")"
fi

# Load runtime library (config_get, is_module_enabled, etc.)
if [ -r "${DCFG_ROOT}/lib/runtime.sh" ]; then
    . "${DCFG_ROOT}/lib/runtime.sh"
fi

# ============================================================
# Shell Options
# ============================================================
shopt -s histappend      # Append to history, don't overwrite
shopt -s checkwinsize    # Update LINES and COLUMNS after each command
shopt -s globstar 2>/dev/null  # ** matches recursively (bash 4+)

# ============================================================
# History
# ============================================================
HISTCONTROL=ignoreboth   # Ignore duplicates and lines starting with space
HISTSIZE=10000
HISTFILESIZE=20000

# ============================================================
# Source POSIX Shared Modules
# ============================================================
if [ -d "${DCFG_ROOT}/shell/posix" ]; then
    for module in "${DCFG_ROOT}/shell/posix"/*.sh; do
        [ -r "$module" ] && . "$module"
    done
fi

# Source platform-specific POSIX module
_platform=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ -r "${DCFG_ROOT}/shell/posix/platforms/${_platform}.sh" ]; then
    . "${DCFG_ROOT}/shell/posix/platforms/${_platform}.sh"
fi
unset _platform

# ============================================================
# Source Bash-Specific Modules
# ============================================================
if [ -d "${DCFG_ROOT}/shell/bash/modules" ]; then
    for module in "${DCFG_ROOT}/shell/bash/modules"/*.sh; do
        [ -r "$module" ] && . "$module"
    done
fi

# ============================================================
# Prompt
# ============================================================
# Simple prompt with hostname and directory
# Override in modules or local config for fancy prompts (starship, etc.)
if [ -z "$PS1_SET" ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# ============================================================
# Local Overrides (not tracked)
# ============================================================
if [ -r "${DCFG_ROOT}/shell/bash/.bashrc.local" ]; then
    . "${DCFG_ROOT}/shell/bash/.bashrc.local"
fi
