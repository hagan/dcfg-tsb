# ~/.profile - Login shell configuration
# Executed by login shells (SSH, console login, etc.)

# Set PATH to include user's bin directories
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Version manager PATH setup (non-interactive safe)
# These ensure node/python/etc. are available in non-interactive shells
# (e.g., Claude Code, scripts, cron). Full init happens in .bashrc modules.

# nvm: add default node version to PATH
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    # Resolve default alias to actual version for PATH
    if [ -s "$NVM_DIR/alias/default" ]; then
        _nvm_default=$(cat "$NVM_DIR/alias/default")
        case "$_nvm_default" in
            lts/*) _nvm_default=$(ls -1 "$NVM_DIR/versions/node/" 2>/dev/null | sort -V | tail -1) ;;
        esac
        if [ -d "$NVM_DIR/versions/node/${_nvm_default}/bin" ]; then
            PATH="$NVM_DIR/versions/node/${_nvm_default}/bin:$PATH"
        fi
        unset _nvm_default
    fi
fi

# pyenv: add to PATH if installed
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
fi

# cargo/rust
. "$HOME/.cargo/env"

# Source .bashrc for interactive bash login shells
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
