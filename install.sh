#!/bin/sh
# Public bootstrap. Install by default; preview is an explicit option.
set -eu
umask 077
usage() {
  cat <<'EOF'
Usage: install.sh [--dry-run | --preview] [--yes] [--source DIRECTORY]
Default: install the manager, download the source, then confirm, back up and apply configs.
--dry-run, --preview  Show config changes without applying them (still downloads manager/source).
--yes                Confirm installation for unattended setup; incompatible with preview.
--apply              Explicit install alias, kept for compatibility.
--source DIRECTORY   Use an existing trusted checkout instead of downloading one.
Tools are optional: run `dotfiles tools` after applying.
EOF
}
apply=true; explicit_apply=false; yes=false; source_dir=''
while [ "$#" -gt 0 ]; do
  case $1 in
    --apply) explicit_apply=true ;;
    --dry-run|--preview) apply=false ;;
    --yes) yes=true ;;
    --source) [ "$#" -ge 2 ] || exit 2; source_dir=$2; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
if [ "$apply" = false ] && { [ "$yes" = true ] || [ "$explicit_apply" = true ]; }; then
  printf '%s\n' '--dry-run/--preview cannot be combined with --yes or --apply' >&2
  exit 2
fi
case $(uname -s) in Darwin) os=darwin ;; Linux) os=linux ;; *) printf 'Use macOS or Linux (WSL on Windows).\n' >&2; exit 1 ;; esac
case $(uname -m) in arm64|aarch64) arch=arm64 ;; x86_64|amd64) arch=amd64 ;; *) printf 'Unsupported architecture\n' >&2; exit 1 ;; esac
case $os-$arch in
  darwin-arm64) sha=ec2d0005f369c912ee9891a26c30d65dc0eda51708f06948e5f7a43db69e1aa7 ;;
  darwin-amd64) sha=d865487d6669243c948ee5542087bd95f4ad4ecb5a1311b85cf19f557694fe03 ;;
  linux-arm64) sha=c9e6a6e71eb5291018e161a8426d7c313cd2e8553c2ca4029511fec2a33bc28c ;;
  linux-amd64) sha=6e5827598cbfc02d132b04f95b5ea10efb5b79230e2a4a0e52df4af144a8ee9f ;;
esac
data=${XDG_DATA_HOME:-$HOME/.local/share}
tools=$data/john-dotfiles-tools
manager=${DOTFILES_CHEZMOI:-$tools/2.73.3/chezmoi}
safe_path() {
  checked=$1
  case $checked in /*) ;; *) printf 'Destination must be absolute: %s\n' "$checked" >&2; exit 1 ;; esac
  while [ "$checked" != / ]; do
    [ ! -L "$checked" ] || { printf 'Refusing symlink destination: %s\n' "$checked" >&2; exit 1; }
    checked=${checked%/*}; [ -n "$checked" ] || checked=/
  done
}
if [ ! -x "$manager" ]; then
  [ -z "${DOTFILES_CHEZMOI-}" ] || { printf 'DOTFILES_CHEZMOI is not executable\n' >&2; exit 1; }
  command -v curl >/dev/null || { printf 'Install curl first.\n' >&2; exit 1; }
  temp=$(mktemp -d)
  trap 'rm -rf "$temp"' EXIT HUP INT TERM
  asset=chezmoi_2.73.3_${os}_${arch}.tar.gz
  printf 'Downloading verified chezmoi v2.73.3 (%s/%s)…\n' "$os" "$arch"
  curl -fsSL --proto '=https' --tlsv1.2 "https://github.com/twpayne/chezmoi/releases/download/v2.73.3/$asset" -o "$temp/archive"
  if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$temp/archive"); else actual=$(shasum -a 256 "$temp/archive"); fi
  [ "${actual%% *}" = "$sha" ] || { printf 'Checksum mismatch. Download was not executed.\n' >&2; exit 1; }
  tar -xzf "$temp/archive" -C "$temp" chezmoi
  safe_path "$manager"
  mkdir -p "$tools/2.73.3"
  install -m 755 "$temp/chezmoi" "$manager"
fi
if [ -z "$source_dir" ]; then
  source_dir=$data/john-dotfiles
  safe_path "$source_dir"
  command -v git >/dev/null || { printf 'Install Git, then rerun this command.\n' >&2; exit 1; }
  if [ ! -e "$source_dir" ]; then
    mkdir -p "$data"
    git clone --branch main --single-branch https://github.com/johnhenning/dotfiles.git "$source_dir"
  else
    [ ! -L "$source_dir" ] && [ -d "$source_dir/.git" ] || { printf 'Source destination is not a regular Git checkout: %s\n' "$source_dir" >&2; exit 1; }
    [ "$(git -C "$source_dir" remote get-url origin)" = https://github.com/johnhenning/dotfiles.git ] || { printf 'Unexpected source repository; review it using --source explicitly.\n' >&2; exit 1; }
    printf 'Using existing checkout: %s (run dotfiles update to fetch changes)\n' "$source_dir"
  fi
fi
source_dir=$(cd "$source_dir" && pwd -P)
[ -f "$source_dir/scripts/manage.sh" ] || { printf 'Incomplete source checkout\n' >&2; exit 1; }
export DOTFILES_SOURCE=$source_dir DOTFILES_CHEZMOI=$manager
if [ "$apply" = true ]; then
  if [ "$yes" = true ]; then sh "$source_dir/scripts/manage.sh" apply --yes; else sh "$source_dir/scripts/manage.sh" apply; fi
else
  sh "$source_dir/scripts/manage.sh" diff
  printf '\nPreview only. No configs applied. Install with:\n  sh "%s/install.sh" --source "%s"\n' "$source_dir" "$source_dir"
fi
