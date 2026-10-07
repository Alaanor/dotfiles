export PNPM_HOME="/home/max/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
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
setopt glob_complete
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# tmux: ensure daily sessions exist, then attach
if [ -z "$TMUX" ] && [[ "$TERM_PROGRAM" != "zed" ]] && command -v tmux >/dev/null 2>&1; then
  tmux start-server
  tmux has-session -t main           2>/dev/null || tmux new-session -d -s main
  tmux has-session -t kimchi-process 2>/dev/null || tmux new-session -d -s kimchi-process
  exec tmux attach-session -t main
fi

source /usr/share/nvm/init-nvm.sh

# fzf keybindings + completion
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# Key bindings
bindkey -e

# Home / End — bind normal, application-cursor, and vt variants so it works
# regardless of the terminal's keypad mode (tmux, xterm, foot, alacritty, …)
bindkey '^[[H'  beginning-of-line; bindkey '^[OH' beginning-of-line; bindkey '^[[1~' beginning-of-line
bindkey '^[[F'  end-of-line;       bindkey '^[OF' end-of-line;       bindkey '^[[4~' end-of-line

# Delete / Insert
bindkey '^[[3~' delete-char
bindkey '^[[2~' overwrite-mode

# Word motion: Ctrl+Left/Right and Alt+Left/Right
bindkey '^[[1;5C' forward-word; bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word; bindkey '^[[1;3D' backward-word
bindkey '^[Oc'    forward-word; bindkey '^[Od'    backward-word

# Ctrl+Backspace / Ctrl+Delete — delete previous / next word
bindkey '^H'      backward-kill-word
bindkey '^[[3;5~' kill-word

# Shift+Tab cycles completion backwards
bindkey '^[[Z'    reverse-menu-complete

# Aliases
alias _='sudo'
alias dotfile='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias dnd='dragon-drag-and-drop --and-exit'
alias ssh='TERM=xterm-256color ssh'
alias clanker='setfacl -m u:clanker:x "$XDG_RUNTIME_DIR" && sudo -H -u clanker env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" /home/clanker/.local/bin/claude'
alias clanker-codex='setfacl -m u:clanker:x "$XDG_RUNTIME_DIR" && sudo -H -u clanker env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" /home/clanker/.local/bin/codex'

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# bun completions
[ -s "/home/max/.bun/_bun" ] && source "/home/max/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
