# Linux-specific shell configuration

# Use systemctl for service management
alias sctl='systemctl'
alias sctlu='systemctl --user'
alias jctl='journalctl'
alias jctlu='journalctl --user'

# Package manager detection and aliases
if command -v apt &>/dev/null; then
    alias apt-update='sudo apt update && sudo apt upgrade'
    alias apt-search='apt search'
    alias apt-install='sudo apt install'
fi

# Open file manager
if command -v xdg-open &>/dev/null; then
    alias open='xdg-open'
fi
