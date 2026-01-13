# macOS-specific shell configuration

# Homebrew setup (differs by architecture)
if [ -d "/opt/homebrew" ]; then
    # Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d "/usr/local/Homebrew" ]; then
    # Intel
    eval "$(/usr/local/bin/brew shellenv)"
fi

# macOS-specific aliases
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Flush DNS cache
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# Use GNU coreutils if installed (prefixed with 'g')
if command -v gls &>/dev/null; then
    alias ls='gls --color=auto'
fi
