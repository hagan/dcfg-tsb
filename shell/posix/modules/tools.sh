# Shell enhancement tools
# Conditionally loads direnv, fzf, starship if installed

# =============================================================================
# direnv - directory-specific environment variables
# =============================================================================
if command -v direnv >/dev/null 2>&1; then
    if [ -n "$BASH_VERSION" ]; then
        eval "$(direnv hook bash)"
    elif [ -n "$ZSH_VERSION" ]; then
        eval "$(direnv hook zsh)"
    fi
fi

# =============================================================================
# fzf - fuzzy finder
# =============================================================================
if command -v fzf >/dev/null 2>&1; then
    # Default options
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

    # Use fd if available (faster than find)
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi

    # Source fzf keybindings and completion
    if [ -n "$BASH_VERSION" ]; then
        [ -f /usr/share/fzf/key-bindings.bash ] && . /usr/share/fzf/key-bindings.bash
        [ -f /usr/share/fzf/completion.bash ] && . /usr/share/fzf/completion.bash
        # Debian/Ubuntu location
        [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
        [ -f /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash
    elif [ -n "$ZSH_VERSION" ]; then
        [ -f /usr/share/fzf/key-bindings.zsh ] && . /usr/share/fzf/key-bindings.zsh
        [ -f /usr/share/fzf/completion.zsh ] && . /usr/share/fzf/completion.zsh
        # Debian/Ubuntu location
        [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && . /usr/share/doc/fzf/examples/key-bindings.zsh
        [ -f /usr/share/doc/fzf/examples/completion.zsh ] && . /usr/share/doc/fzf/examples/completion.zsh
    fi
fi

# =============================================================================
# starship - cross-shell prompt
# =============================================================================
if command -v starship >/dev/null 2>&1; then
    if [ -n "$BASH_VERSION" ]; then
        eval "$(starship init bash)"
        export PS1_SET=1  # Prevent default prompt from loading
    elif [ -n "$ZSH_VERSION" ]; then
        eval "$(starship init zsh)"
        export PROMPT_SET=1  # Prevent default prompt from loading
    fi
fi

# =============================================================================
# zoxide - smarter cd command
# =============================================================================
if command -v zoxide >/dev/null 2>&1; then
    if [ -n "$BASH_VERSION" ]; then
        eval "$(zoxide init bash)"
    elif [ -n "$ZSH_VERSION" ]; then
        eval "$(zoxide init zsh)"
    fi
fi
