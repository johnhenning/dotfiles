#!/bin/sh
set -eu
umask 077
case ${1-} in ''|--apply) ;; *) printf 'Usage: dotfiles tools [--apply]\n' >&2; exit 2 ;; esac
[ "$#" -le 1 ] || exit 2
source_dir=${DOTFILES_SOURCE:-${XDG_DATA_HOME:-$HOME/.local/share}/john-dotfiles}
platform=$(uname -s)-$(uname -m)
. "$source_dir/scripts/vendors.sh"
missing=''
for tool in git bash zsh tmux direnv; do
  command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
done
uv_needed=false; command -v uv >/dev/null 2>&1 || uv_needed=true
nvim_needed=true
if command -v nvim >/dev/null 2>&1 && nvim --version | awk 'NR==1 {sub(/^v/,"",$2);split($2,v,".");exit !(v[1]>0 || v[2]>=11)}'; then nvim_needed=false; fi
printf 'Tool plan (existing uv and compatible Neovim are preserved):\n'
printf '  System packages:%s\n  uv %s needed: %s\n  Neovim %s needed: %s\n' "${missing:- none}" "$uv_version" "$uv_needed" "$nvim_version" "$nvim_needed"
if [ "${1-}" != --apply ]; then printf '\nReview, then run: dotfiles tools --apply\n'; exit 0; fi
if [ -n "$missing" ]; then
  if [ "$(uname -s)" = Darwin ]; then
    command -v brew >/dev/null 2>&1 || { printf 'Install Homebrew from https://brew.sh first, or install the listed tools with Outfit.\n' >&2; exit 1; }
    # Intentional splitting: missing contains only fixed tool identifiers above.
    # shellcheck disable=SC2086
    brew install $missing
  elif command -v apt-get >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then sudo_cmd=''; else sudo_cmd=sudo; fi
    $sudo_cmd apt-get update
    # shellcheck disable=SC2086
    $sudo_cmd apt-get install -y $missing
  elif command -v dnf >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then sudo_cmd=''; else sudo_cmd=sudo; fi
    # shellcheck disable=SC2086
    $sudo_cmd dnf install -y $missing
  else printf 'Install the listed system tools using your package manager.\n' >&2; exit 1
  fi
fi
[ "$uv_needed" = true ] || [ "$nvim_needed" = true ] || { printf 'Tools are ready.\n'; exit 0; }
temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT HUP INT TERM
bin=$HOME/.local/bin
tools=${XDG_DATA_HOME:-$HOME/.local/share}/john-dotfiles-tools
safe_path() {
  checked=$1
  while [ "$checked" != / ]; do
    [ ! -L "$checked" ] || { printf 'Refusing symlink destination: %s\n' "$checked" >&2; exit 1; }
    checked=${checked%/*}; [ -n "$checked" ] || checked=/
  done
}
safe_path "$bin"; safe_path "$tools"
mkdir -p "$bin" "$tools"
backup_binary() {
  safe_path "$1"
  if [ -e "$1" ]; then
    [ -f "$1" ] || { printf 'Expected a regular tool file: %s\n' "$1" >&2; exit 1; }
    saved=$(mktemp -d "$tools/replaced-tool-XXXXXXXX")
    mv "$1" "$saved/${1##*/}"
    printf 'Previous tool saved to %s\n' "$saved"
  fi
}
fetch() {
  curl -fsSL --proto '=https' --tlsv1.2 "$1" -o "$temp/archive"
  if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$temp/archive"); else actual=$(shasum -a 256 "$temp/archive"); fi
  [ "${actual%% *}" = "$2" ] || { printf 'Checksum mismatch; not extracting or executing download.\n' >&2; exit 1; }
  tar -xzf "$temp/archive" -C "$temp"
}
if [ "$uv_needed" = true ]; then
  safe_path "$bin/uv"; safe_path "$bin/uvx"
  fetch "https://github.com/astral-sh/uv/releases/download/$uv_version/$uv_asset.tar.gz" "$uv_sha"
  backup_binary "$bin/uv"; backup_binary "$bin/uvx"
  install -m 755 "$temp/$uv_asset/uv" "$bin/uv"
  install -m 755 "$temp/$uv_asset/uvx" "$bin/uvx"
fi
if [ "$nvim_needed" = true ]; then
  safe_path "$bin/nvim"; safe_path "$tools/nvim-$nvim_version"
  [ ! -e "$tools/nvim-$nvim_version" ] || { printf 'Neovim destination already exists; inspect it first.\n' >&2; exit 1; }
  fetch "https://github.com/neovim/neovim/releases/download/v$nvim_version/$nvim_asset.tar.gz" "$nvim_sha"
  mv "$temp/$nvim_asset" "$tools/nvim-$nvim_version"
  backup_binary "$bin/nvim"
  ln -s "$tools/nvim-$nvim_version/bin/nvim" "$bin/nvim"
fi
printf '\nTools installed. Open a new terminal. Neovim downloads its locked plugins on first launch.\n'
