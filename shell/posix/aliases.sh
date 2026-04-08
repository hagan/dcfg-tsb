# Common aliases - shared between bash and zsh

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# List files
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Colorize output (if supported)
if ls --color=auto &>/dev/null; then
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Disk usage
alias df='df -h'
alias du='du -h'

# dcfg-tsb shortcuts
alias dcfg='cd ~/.dcfg-tsb'
alias dcfg-doctor='~/.dcfg-tsb/scripts/doctor.sh'
alias dcfg-symlinks='~/.dcfg-tsb/scripts/setup-symlinks.sh'
alias dcfg-sync='~/.dcfg-tsb/scripts/sync-sensitive.sh'

# =============================================================================
# Shell switching
# =============================================================================
# Quick switch to another shell (replaces current shell)
# Usage: tozsh, tobash, tofish, tonu

tozsh() {
    if command -v zsh >/dev/null 2>&1; then
        exec zsh "$@"
    else
        echo "zsh not installed" >&2
        return 1
    fi
}

tobash() {
    if command -v bash >/dev/null 2>&1; then
        exec bash "$@"
    else
        echo "bash not installed" >&2
        return 1
    fi
}

tofish() {
    if command -v fish >/dev/null 2>&1; then
        exec fish "$@"
    else
        echo "fish not installed" >&2
        return 1
    fi
}

tonu() {
    if command -v nu >/dev/null 2>&1; then
        exec nu "$@"
    else
        echo "nushell not installed" >&2
        return 1
    fi
}

# Show current and available shells
shells() {
    echo "Current: $0"
    echo "Default: $(getent passwd "$USER" | cut -d: -f7)"
    echo ""
    echo "Available:"
    for sh in bash zsh fish nu; do
        if command -v "$sh" >/dev/null 2>&1; then
            printf "  %-8s %s\n" "$sh" "$(command -v "$sh")"
        fi
    done
}

# =============================================================================
# Tmux shell sessions
# =============================================================================
# Create named tmux sessions with specific shells
# Usage: tmux-zsh [session-name]

tmux-bash() {
    local name="${1:-bash}"
    if command -v tmux >/dev/null 2>&1; then
        tmux new-session -s "$name" bash
    else
        echo "tmux not installed" >&2
        return 1
    fi
}

tmux-zsh() {
    local name="${1:-zsh}"
    if command -v tmux >/dev/null 2>&1 && command -v zsh >/dev/null 2>&1; then
        tmux new-session -s "$name" zsh
    else
        echo "tmux or zsh not installed" >&2
        return 1
    fi
}

tmux-fish() {
    local name="${1:-fish}"
    if command -v tmux >/dev/null 2>&1 && command -v fish >/dev/null 2>&1; then
        tmux new-session -s "$name" fish
    else
        echo "tmux or fish not installed" >&2
        return 1
    fi
}

tmux-nu() {
    local name="${1:-nu}"
    if command -v tmux >/dev/null 2>&1 && command -v nu >/dev/null 2>&1; then
        tmux new-session -s "$name" nu
    else
        echo "tmux or nushell not installed" >&2
        return 1
    fi
}

# =============================================================================
# Tool wrappers
# =============================================================================

# npm init with author info from git config
npm-init() {
    local name email
    name="$(git config user.name 2>/dev/null)"
    email="$(git config user.email 2>/dev/null)"

    if [ -z "$name" ] || [ -z "$email" ]; then
        echo "Warning: git user.name or user.email not set" >&2
        npm init "$@"
    else
        npm init --init-author-name="$name" --init-author-email="$email" "$@"
    fi
}
