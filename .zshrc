# pnpm
export PNPM_HOME="/home/max/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
export PATH="$HOME/.local/bin:$PATH"

if [[ "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
    return 0
fi

export GTK2_RC_FILES=$HOME/.gtkrc-2.0

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space hist_expire_dups_first inc_append_history autocd

# Completion
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# tmux: ensure daily sessions exist, then attach
if [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
  tmux start-server
  tmux has-session -t main           2>/dev/null || tmux new-session -d -s main
  tmux has-session -t kimchi-process 2>/dev/null || tmux new-session -d -s kimchi-process
  exec tmux attach-session -t main
fi

source /usr/share/nvm/init-nvm.sh

# fzf keybindings + completion
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# Aliases
alias _='sudo'
alias dotfile='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias dnd='dragon-drag-and-drop --and-exit'
alias ssh='TERM=xterm-256color ssh'

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
