# History size
export HISTSIZE=10000
export HISTFILESIZE=10000

# Oh‑My‑Zsh base
export ZSH="$HOME/.oh-my-zsh"
FPATH=$ZSH/custom/plugins/zsh-completions/src:$FPATH

ZSH_THEME="dracula-pro"   # falls back to "dracula" automatically
plugins=(git autoupdate zsh-syntax-highlighting zsh-autosuggestions \
         zsh-completions jsontools)
source $ZSH/oh-my-zsh.sh

# Aliases
alias vi='/usr/bin/nvim -u ~/.nvimrc'
alias vim='/usr/bin/nvim -u ~/.nvimrc'
alias nvim='/usr/bin/nvim -u ~/.nvimrc'
alias l='lsd -l'
alias ll='lsd -la'
alias ls='lsd'
