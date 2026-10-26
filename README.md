# John's dotfiles

[![Checks](https://github.com/johnhenning/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/johnhenning/dotfiles/actions/workflows/ci.yml)

Reusable Zsh, Bash, PATH, tmux, uv, Git and Neovim configuration, independent
of [Outfit](https://getoutfit.dev/), which manages app selections. Public configs
contain no credentials; sign in to 1Password and individual services afterward.

## Quick setup

Requires macOS or Linux on ARM64/x86-64, with curl, tar and Git. Debian/Ubuntu,
Fedora and WSL use the same configs. Native Windows shells are not supported.

Preview first (downloads the repo and a pinned, checksum-verified chezmoi):

```sh
curl -fsSL https://raw.githubusercontent.com/johnhenning/dotfiles/main/install.sh | sh
```

Apply after reviewing the diff:

```sh
curl -fsSL https://raw.githubusercontent.com/johnhenning/dotfiles/main/install.sh | sh -s -- --apply
```

Apply asks for confirmation through your terminal. `--apply --yes` enables an
explicitly unattended setup. Existing managed files are backed up privately
under `~/.local/state/john-dotfiles/backups/` before replacement. Symlink targets
or ancestors are rejected for manual review. Unmanaged files are kept. Applying
replaces existing rc files: move settings you want to retain into the local
modules below after reviewing the backup. Backups are never uploaded.

Open a new terminal, then optionally install missing tools and frameworks:

```sh
dotfiles tools              # show the plan
dotfiles tools --apply      # system packages + pinned uv/Neovim when needed
dotfiles plugins            # show optional framework plan
dotfiles plugins --apply    # pinned Oh My Zsh, Powerlevel10k and TPM
dotfiles doctor
```

macOS tools use an existing Homebrew installation; install Homebrew through
Outfit or [brew.sh](https://brew.sh/) first. Linux tools use apt or dnf and may
need sudo. Compatible existing Neovim (0.11+) and existing uv are preserved.
Fallbacks are uv 0.13.5 and Neovim 0.12.6. Tools do not edit startup files, switch
your login shell, install project dependencies or sign in to accounts. System
package versions follow your OS repositories.

## PATH without rc-file clutter

The rc files only load modules. Bash and Zsh share `~/.config/shell/path.sh`,
which deduplicates inherited PATH entries, drops empty entries, and includes
`~/.local/bin` plus Homebrew on Apple Silicon when present. Paths with spaces
and inherited system entries are preserved.

For intentional global additions, create `~/.config/shell/path.local.sh`:

```sh
path_prepend "$HOME/.cargo/bin"
path_append "$HOME/tools/some-sdk/bin"
```

Or use separate `~/.config/shell/path.d/*.sh` fragments. Missing directories are
ignored; entries containing `:` are rejected. These local files survive updates.
Use `path_show` to inspect the result. For one command without changing your shell:

```sh
with_path "$HOME/tools/special-sdk/bin" special-command --help
```

For project tools, prefer `uv run python main.py` or `uvx ruff check .`.
For tools needed throughout a project session, copy `examples/project.envrc`
into the project, review it, and explicitly run `direnv allow`. Its `.venv/bin`,
`node_modules/.bin` and `.tools/bin` additions unload when you leave the project.
No project is automatically trusted. See [direnv](https://direnv.net/) and
[uv tool isolation](https://docs.astral.sh/uv/concepts/tools/).

## Preserved settings

- Neovim: the workstation's NvChad v2.5 config and 27-plugin lockfile, onedark
  theme, Lua LSP, stylua choices, `;` command mode and `jk` escape. The bootstrap
  now checks clone failures and pins lazy.nvim to the existing lockfile commit.
  Neovim downloads plugins on first launch; `:Lazy restore` restores the lock.
  Language servers and external formatters may need installation through Mason.
- tmux: Ctrl-Space prefix, Vim pane movement, Alt-arrow navigation, vi copy mode,
  pane-directory splits, Catppuccin macchiato and existing plugin choices.
  Optional TPM bootstrap is pinned. Press Ctrl-Space then Shift-I to fetch tmux
  plugins; their versions follow upstream defaults, independently of the Neovim lock.
- Zsh: history, completion, optional Oh My Zsh and Powerlevel10k. Existing
  framework checkouts and `~/.p10k.zsh` are kept; a simple prompt works without
  frameworks. Run `p10k configure` after optional framework installation.
- Bash: equivalent shared PATH, aliases, editor choices and history, with a simple
  prompt. Both shells integrate direnv when present and use uv. No mise activation.

Your login shell stays unchanged. Choose a Nerd Font in your terminal for icons.
Existing `~/.tmux.conf` or `~/.gitconfig` may take precedence over XDG configs:
inspect and merge them rather than keeping competing definitions.

## Local and private settings

Keep these outside this public repo:

- `~/.config/shell/path.local.sh` and `path.d/*.sh`: intentional global tools.
- `~/.config/shell/local.sh`: shared settings and functions.
- `~/.config/zsh/local.zsh`, `~/.config/bash/local.bash`: shell-specific settings.
- `~/.config/tmux/local.conf`: machine-specific tmux settings.
- `~/.config/git/local.config`: identity and signing preferences.
- `~/.p10k.zsh`: optional prompt customization.

Use 1Password CLI references or `op run` when a process needs secrets. The repo
does not export keys or persist sessions. `examples/1password-macos.conf` is an
opt-in macOS SSH agent example: enable the agent, review the fragment, and include
it from your existing SSH config. Linux uses a different agent socket. Private
host entries remain local. See [1Password SSH setup](https://developer.1password.com/docs/ssh/get-started/).

The managed layout uses `~/.config`. Applying with a different XDG_CONFIG_HOME
stops for manual configuration rather than splitting settings across roots.

## Updates and recovery

```sh
dotfiles update    # fast-forward a clean checkout; show the diff
dotfiles diff
dotfiles apply     # confirm; back up; apply
dotfiles status
```

Source lives in `${XDG_DATA_HOME:-~/.local/share}/john-dotfiles`. Manager state
and cache are separate from any existing chezmoi setup. Local source edits block
updates until committed or stashed. Rerunning bootstrap uses the existing clone
without pulling changes.

To recover a file, inspect the printed backup's `files.tar.gz` using `tar -tzf`,
extract the selected file to a scratch directory and copy it back. `managed.txt`
lists managed files; new files have no previous backup. Package installation is
not rolled back by restoring configs.

For an existing clone, use `sh install.sh --source "$PWD"`; keep DOTFILES_SOURCE
set to that trusted checkout when using the helper. Normal one-line setup uses
the stable source location automatically.

## Development and releases

Read [AGENTS.md](AGENTS.md) and [docs-design.md](docs-design.md). Run:

```sh
DOTFILES_CHEZMOI=/absolute/path/to/verified/chezmoi python3 -m unittest discover -s tests -v
```

Tests use temporary homes for backup, idempotence, symlink refusal, shell startup,
PATH ordering, local overrides and scoped tools. CI runs macOS and Linux plus
locked NvChad restore in disposable Linux. Fedora and WSL still need clean-machine
testing. Release CI reruns checks, packages the exact source commit with SHA-256
checksums and provenance, and creates a draft. Quick setup follows `main`.
For fixed configs, check out a release tag and use `--source` with that checkout.

MIT for authored files; the preserved NvChad starter retains its original
[public-domain license](home/dot_config/nvim/LICENSE). Frameworks, plugins and
vendor binaries retain their own licenses.
