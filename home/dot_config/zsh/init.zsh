[[ -o interactive ]] || return
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/common.sh"
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY AUTO_CD
bindkey -e
if [[ -r "${ZSH:-$HOME/.oh-my-zsh}/oh-my-zsh.sh" ]]; then
  export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
  plugins=(git)
  command -v docker >/dev/null 2>&1 && plugins+=(docker)
  ZSH_THEME=''
  if [[ -r "$ZSH/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    ZSH_THEME='powerlevel10k/powerlevel10k'
  fi
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
  autoload -Uz colors && colors
  PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '
fi
[[ ! -r "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"
if command -v uv >/dev/null 2>&1; then eval "$(uv generate-shell-completion zsh)"; fi
[[ ! -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh" ]] || source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh"
# Install hooks last so other prompt setup cannot overwrite them.
if command -v direnv >/dev/null 2>&1; then eval "$(direnv hook zsh)"; fi
