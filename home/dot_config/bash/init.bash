. "${XDG_CONFIG_HOME:-$HOME/.config}/shell/common.sh"
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/bash/history"
mkdir -p "${HISTFILE%/*}"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
bind 'set completion-ignore-case on'
PS1='\[\e[32m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\] \$ '
if command -v uv >/dev/null 2>&1; then eval "$(uv generate-shell-completion bash)"; fi
[ ! -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash/local.bash" ] || . "${XDG_CONFIG_HOME:-$HOME/.config}/bash/local.bash"
if command -v direnv >/dev/null 2>&1; then eval "$(direnv hook bash)"; fi
