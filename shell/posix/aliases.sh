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
