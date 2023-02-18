# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Variable
export ZSH="/home/max/.oh-my-zsh"
export FZF_BASE=/usr/bin/fzf

# gtk theme
export GTK2_RC_FILES=$HOME/.gtkrc-2.0

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  fzf
  archlinux
  npm
  autoupdate
)

source $ZSH/oh-my-zsh.sh
source /usr/share/nvm/init-nvm.sh

# Aliases
alias dotfile='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias dnd='dragon-drag-and-drop --and-exit'
alias ssh='TERM=xterm-256color ssh'


# exec p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

autoload -U +X bashcompinit && bashcompinit
