# Shared by bash and zsh. No eval, word splitting or project auto-discovery.
path_remove() {
  local _dotfiles_remove=$1 _dotfiles_rest=${PATH-}: _dotfiles_item _dotfiles_result=''
  while [ -n "$_dotfiles_rest" ]; do
    _dotfiles_item=${_dotfiles_rest%%:*}
    _dotfiles_rest=${_dotfiles_rest#*:}
    [ -n "$_dotfiles_item" ] || continue
    [ "$_dotfiles_item" != "$_dotfiles_remove" ] || continue
    case ":$_dotfiles_result:" in *":$_dotfiles_item:"*) continue ;; esac
    _dotfiles_result=${_dotfiles_result:+$_dotfiles_result:}$_dotfiles_item
  done
  PATH=$_dotfiles_result
  export PATH
}
path_prepend() {
  [ "$#" -eq 1 ] || return 2
  case $1 in *:*) printf 'PATH entries cannot contain a colon: %s\n' "$1" >&2; return 2 ;; esac
  [ -d "$1" ] || return 0
  path_remove "$1"
  PATH=$1${PATH:+:$PATH}
  export PATH
}
path_append() {
  [ "$#" -eq 1 ] || return 2
  case $1 in *:*) printf 'PATH entries cannot contain a colon: %s\n' "$1" >&2; return 2 ;; esac
  [ -d "$1" ] || return 0
  path_remove "$1"
  PATH=${PATH:+$PATH:}$1
  export PATH
}
with_path() (
  [ "$#" -ge 2 ] || { printf 'Usage: with_path DIRECTORY COMMAND [ARG...]\n' >&2; exit 2; }
  [ -d "$1" ] || { printf 'No such tool directory: %s\n' "$1" >&2; exit 1; }
  path_prepend "$1" || exit
  shift
  command "$@"
)
path_show() { printf '%s\n' "$PATH" | tr ':' '\n'; }

# Deduplicate inherited entries, preserving their order and dropping empty ones.
path_remove ''
# Only shared, intentional user tools belong here. Project tools do not.
if [ -d /opt/homebrew/bin ]; then
  path_prepend /opt/homebrew/sbin
  path_prepend /opt/homebrew/bin
fi
path_prepend "$HOME/.local/bin"
# Local files are opt-in global additions, never committed in this repo.
_dotfiles_load_paths() {
  # zsh otherwise aborts sourcing when no optional fragments exist.
  if [ -n "${ZSH_VERSION-}" ]; then setopt localoptions nonomatch; fi
  local _dotfiles_path_file
  for _dotfiles_path_file in "${XDG_CONFIG_HOME:-$HOME/.config}"/shell/path.d/*.sh; do
    [ ! -r "$_dotfiles_path_file" ] || . "$_dotfiles_path_file"
  done
}
_dotfiles_load_paths
[ ! -r "${XDG_CONFIG_HOME:-$HOME/.config}/shell/path.local.sh" ] || . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/path.local.sh"
unset -f _dotfiles_load_paths
