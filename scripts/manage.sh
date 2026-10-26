#!/bin/sh
set -eu
umask 077
source_dir=${DOTFILES_SOURCE:-${XDG_DATA_HOME:-$HOME/.local/share}/john-dotfiles}
manager=${DOTFILES_CHEZMOI:-${XDG_DATA_HOME:-$HOME/.local/share}/john-dotfiles-tools/2.73.3/chezmoi}
state=${XDG_STATE_HOME:-$HOME/.local/state}/john-dotfiles
cache=${XDG_CACHE_HOME:-$HOME/.cache}/john-dotfiles
safe_path() {
  checked=$1
  case $checked in /*) ;; *) printf 'Destination must be absolute: %s\n' "$checked" >&2; exit 1 ;; esac
  while [ "$checked" != / ]; do
    [ ! -L "$checked" ] || { printf 'Refusing symlink destination: %s\n' "$checked" >&2; exit 1; }
    checked=${checked%/*}; [ -n "$checked" ] || checked=/
  done
}
safe_path "$state/state.boltdb"
safe_path "$state/backups"
safe_path "$cache"
case $HOME in *'
'*) printf 'Newlines in HOME are unsupported\n' >&2; exit 1 ;; esac
[ -x "$manager" ] || { printf 'Run install.sh to install the configuration manager.\n' >&2; exit 1; }
[ -d "$source_dir/home" ] || { printf 'Dotfiles source missing: %s\n' "$source_dir" >&2; exit 1; }
cm() {
  "$manager" --source "$source_dir" --destination "$HOME" --config "$source_dir/chezmoi.toml" \
    --persistent-state "$state/state.boltdb" --cache "$cache" --no-pager "$@"
}
action=${1:-help}; [ "$#" -eq 0 ] || shift
case $action in
  diff|status) [ "$#" -eq 0 ] || exit 2; cm "$action" ;;
  apply)
    case ${1-} in ''|--yes) ;; *) printf 'Usage: dotfiles apply [--yes]\n' >&2; exit 2 ;; esac
    [ "$#" -le 1 ] || exit 2
    # Source layout is ~/.config. Never silently split configs across two roots.
    [ "${XDG_CONFIG_HOME:-$HOME/.config}" = "$HOME/.config" ] || { printf 'Custom XDG_CONFIG_HOME: review/copy selected modules manually.\n' >&2; exit 1; }
    cm diff
    if [ "${1-}" != --yes ]; then
      printf '\nBack up and apply these configs? [y/N] ' >/dev/tty
      read -r answer </dev/tty
      case $answer in y|Y|yes) ;; *) printf 'No config files changed.\n'; exit 0 ;; esac
    fi
    mkdir -p "$state/backups"
    backup=$(mktemp -d "$state/backups/apply-XXXXXXXX")
    cm managed --include files --path-style relative >"$backup/managed.txt"
    : >"$backup/existing.txt"
    while IFS= read -r relative; do
      target=$HOME/$relative
      check=$target
      while [ "$check" != / ]; do
        [ ! -L "$check" ] || { printf 'Refusing symlink target or ancestor: %s\n' "$check" >&2; exit 1; }
        check=${check%/*}; [ -n "$check" ] || check=/
      done
      if [ -e "$target" ]; then
        [ -f "$target" ] || { printf 'Expected a regular file: %s\n' "$target" >&2; exit 1; }
        printf '%s\n' "$relative" >>"$backup/existing.txt"
      fi
    done <"$backup/managed.txt"
    tar -czf "$backup/files.tar.gz" -C "$HOME" -T "$backup/existing.txt"
    printf 'Existing managed files backed up to %s\n' "$backup"
    cm --force apply
    printf '\nDotfiles applied successfully.\nOpen a new terminal to load the shell settings.\nOptional tools: dotfiles tools\nPreview updates: dotfiles update\n'
    ;;
  update)
    [ "$#" -eq 0 ] || exit 2
    [ -z "$(git -C "$source_dir" status --porcelain)" ] || { printf 'Source has local edits; commit or stash them before updating.\n' >&2; exit 1; }
    git -C "$source_dir" pull --ff-only
    cm diff
    printf '\nReview the diff, then run: dotfiles apply\n'
    ;;
  tools) exec sh "$source_dir/scripts/tools.sh" "$@" ;;
  plugins) exec sh "$source_dir/scripts/plugins.sh" "$@" ;;
  doctor)
    for tool in bash zsh git tmux uv nvim direnv; do
      if command -v "$tool" >/dev/null 2>&1; then printf 'available  %s: %s\n' "$tool" "$(command -v "$tool")"; else printf 'missing    %s\n' "$tool"; fi
    done
    printf '\nSource: %s\nState/backups: %s\n' "$source_dir" "$state"
    ;;
  help|-h|--help) printf 'Usage: dotfiles {diff|status|apply [--yes]|update|tools [--apply]|plugins [--apply]|doctor}\n' ;;
  *) printf 'Unknown command: %s\n' "$action" >&2; exit 2 ;;
esac
