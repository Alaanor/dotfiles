# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Variable
export PATH=$HOME/bin:/usr/local/bin:$HOME/.dotnet/tools:$PATH
export ZSH="/home/max/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  fzf
  archlinux
  npm
)

export FZF_BASE=/usr/bin/fzf
source /usr/share/zsh/plugins/alias-tips/alias-tips.plugin.zsh

# oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Aliases
alias dotfile='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias dnd='dragon-drag-and-drop --and-exit'

# exec p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
