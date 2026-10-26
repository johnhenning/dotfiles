# Shared shell behavior. Keep project activation in direnv or explicit commands.
. "${XDG_CONFIG_HOME:-$HOME/.config}/shell/path.sh"
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  alias vim=nvim
else
  export EDITOR=${EDITOR:-vi}
fi
if command -v code >/dev/null 2>&1; then export VISUAL='code --wait'
else export VISUAL=$EDITOR; fi
alias ll='ls -lah'
alias ..='cd ..'
alias ur='uv run'
alias ux='uvx'
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/shell/local.sh" ]; then
  . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/local.sh"
fi
