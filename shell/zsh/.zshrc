# ~/.zshrc - Zsh configuration for dcfg-tsb
# Sources shared POSIX modules and platform-specific configs

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ============================================================
# dcfg-tsb Configuration Loading
# ============================================================
DCFG_ROOT="${DCFG_ROOT:-$HOME/.dcfg-tsb}"

# Load configuration layers and export CONFIG_* variables
if [[ -x "${DCFG_ROOT}/scripts/detect-platform.sh" ]]; then
    eval "$("${DCFG_ROOT}/scripts/detect-platform.sh")"
fi

# Load runtime library (config_get, is_module_enabled, etc.)
if [[ -r "${DCFG_ROOT}/lib/runtime.sh" ]]; then
    source "${DCFG_ROOT}/lib/runtime.sh"
fi

# ============================================================
# Shell Options
# ============================================================
setopt AUTO_CD              # cd by typing directory name
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell
setopt NO_BEEP              # Don't beep on errors
setopt GLOB_DOTS            # Include dotfiles in glob patterns
setopt EXTENDED_GLOB        # Extended pattern matching

# ============================================================
# History
# ============================================================
setopt APPEND_HISTORY       # Append to history, don't overwrite
setopt SHARE_HISTORY        # Share history across sessions
setopt HIST_IGNORE_DUPS     # Ignore duplicate commands
setopt HIST_IGNORE_SPACE    # Ignore commands starting with space
setopt HIST_REDUCE_BLANKS   # Remove extra blanks from commands

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=20000

# ============================================================
# Completion
# ============================================================
autoload -Uz compinit
compinit -d "${HOME}/.zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Case insensitive

# ============================================================
# Source POSIX Shared Modules
# ============================================================
if [[ -d "${DCFG_ROOT}/shell/posix" ]]; then
    for module in "${DCFG_ROOT}/shell/posix"/*.sh; do
        [[ -r "$module" ]] && source "$module"
    done
fi

# Source platform-specific POSIX module
_platform=$(uname -s | tr '[:upper:]' '[:lower:]')
if [[ -r "${DCFG_ROOT}/shell/posix/platforms/${_platform}.sh" ]]; then
    source "${DCFG_ROOT}/shell/posix/platforms/${_platform}.sh"
fi
unset _platform

# ============================================================
# Source Zsh-Specific Modules
# ============================================================
if [[ -d "${DCFG_ROOT}/shell/zsh/modules" ]]; then
    for module in "${DCFG_ROOT}/shell/zsh/modules"/*.zsh; do
        [[ -r "$module" ]] && source "$module"
    done
fi

# ============================================================
# Prompt
# ============================================================
# Simple prompt with hostname and directory
# Override in modules or local config for fancy prompts (starship, etc.)
if [[ -z "$PROMPT_SET" ]]; then
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
fi

# ============================================================
# Local Overrides (not tracked)
# ============================================================
if [[ -r "${DCFG_ROOT}/shell/zsh/.zshrc.local" ]]; then
    source "${DCFG_ROOT}/shell/zsh/.zshrc.local"
fi
