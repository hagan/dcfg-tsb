# Version manager initialization
# Conditionally loads pyenv, nvm, goenv, rustup if installed

# Only run if module is enabled
if command -v is_module_enabled >/dev/null 2>&1; then
    is_module_enabled version_managers || return 0
fi

# =============================================================================
# pyenv - Python version manager
# =============================================================================
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
        # pyenv-virtualenv if installed
        if [ -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
            eval "$(pyenv virtualenv-init -)"
        fi
    fi
fi

# =============================================================================
# nvm - Node version manager
# =============================================================================
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    # Lazy load nvm for faster shell startup
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # Define placeholder functions that load nvm on first use
        __load_nvm() {
            unset -f nvm node npm npx 2>/dev/null
            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        }
        nvm() { __load_nvm && nvm "$@"; }
        node() { __load_nvm && node "$@"; }
        npm() { __load_nvm && npm "$@"; }
        npx() { __load_nvm && npx "$@"; }
    fi
fi

# =============================================================================
# goenv - Go version manager
# =============================================================================
if [ -d "$HOME/.goenv" ]; then
    export GOENV_ROOT="$HOME/.goenv"
    export PATH="$GOENV_ROOT/bin:$PATH"
    if command -v goenv >/dev/null 2>&1; then
        eval "$(goenv init -)"
        # Set GOPATH after goenv init
        export PATH="$GOROOT/bin:$PATH"
        export PATH="$GOPATH/bin:$PATH"
    fi
fi

# =============================================================================
# Rust/Cargo
# =============================================================================
if [ -d "$HOME/.cargo" ]; then
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"
    # Source cargo env if it exists
    [ -f "$CARGO_HOME/env" ] && . "$CARGO_HOME/env"
fi

# =============================================================================
# rustup completions (bash/zsh specific, handled separately)
# =============================================================================
if command -v rustup >/dev/null 2>&1; then
    # Completions are shell-specific, add in bash/zsh modules if needed
    :
fi
