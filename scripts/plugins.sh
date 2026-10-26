#!/bin/sh
set -eu
umask 077
case ${1-} in ''|--apply) ;; *) printf 'Usage: dotfiles plugins [--apply]\n' >&2; exit 2 ;; esac
[ "$#" -le 1 ] || exit 2
printf 'Optional framework plan:\n  Oh My Zsh → ~/.oh-my-zsh\n  Powerlevel10k → ~/.oh-my-zsh/custom/themes/powerlevel10k\n  TPM → ~/.tmux/plugins/tpm\nExisting checkouts are preserved. No shell is changed and no plugins are activated automatically.\n'
[ "${1-}" = --apply ] || { printf '\nRun: dotfiles plugins --apply\n'; exit 0; }
command -v git >/dev/null || { printf 'Install Git first.\n' >&2; exit 1; }
checkout() {
  repo=$1; commit=$2; destination=$3
  current=$destination
  while [ "$current" != / ]; do
    [ ! -L "$current" ] || { printf 'Refusing symlink: %s\n' "$current" >&2; exit 1; }
    current=${current%/*}; [ -n "$current" ] || current=/
  done
  if [ -e "$destination" ]; then printf 'Preserving existing %s\n' "$destination"; return; fi
  mkdir -p "${destination%/*}"
  staging=$(mktemp -d "${destination}.XXXXXXXX")
  trap 'rm -rf "$staging"' EXIT HUP INT TERM
  git -C "$staging" init -q
  git -C "$staging" remote add origin "https://github.com/$repo.git"
  git -C "$staging" fetch --depth 1 origin "$commit"
  git -C "$staging" checkout --detach FETCH_HEAD
  [ "$(git -C "$staging" rev-parse HEAD)" = "$commit" ] || exit 1
  mv "$staging" "$destination"
  trap - EXIT HUP INT TERM
}
checkout ohmyzsh/ohmyzsh d2b7f557cceaddb16ba89bbf8200d8a8df35c4d8 "$HOME/.oh-my-zsh"
checkout romkatv/powerlevel10k d05a1b00f9a61f9578bf9dc19b8451942dde8734 "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
checkout tmux-plugins/tpm 99469c4a9b1ccf77fade25842dc7bafbc8ce9946 "$HOME/.tmux/plugins/tpm"
printf '\nFrameworks ready. Open a new terminal; run p10k configure if desired.\nIn tmux, press Ctrl-Space then Shift-I to install the configured TPM plugins.\n'
