# Variable
export ZSH="/home/max/.oh-my-zsh"
export FZF_BASE=/usr/bin/fzf

# gtk theme
export GTK2_RC_FILES=$HOME/.gtkrc-2.0

# config
ZSH_TMUX_AUTOSTART=true
ZSH_TMUX_CONFIG=/home/max/.config/tmux/tmux.conf

# Plugins
plugins=(
  git
  fzf
  archlinux
  npm
  rust
  tmux
)

source $ZSH/oh-my-zsh.sh
source /usr/share/nvm/init-nvm.sh

# Aliases
alias dotfile='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias dnd='dragon-drag-and-drop --and-exit'
alias ssh='TERM=xterm-256color ssh'

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

autoload -U +X bashcompinit && bashcompinit

