# Standalone dotfiles

The public `johnhenning/dotfiles` repository owns personal shell, Git, tmux,
uv and NvChad configuration. Outfit continues to own software selections.
Configurations are static chezmoi source files under `home/`; no application
hooks, credentials or machine inventory are executed by applying them.

The bootstrap installs a pinned, verified chezmoi executable in a dedicated
data directory and checks out this repository. Installation is the default;
`--dry-run` and `--preview` show config changes without applying them (manager
and source downloads still occur). Applying requires terminal confirmation or
`--yes`, backs up existing managed files locally,
and rejects symlink targets or ancestors. Manager state is separate from any
other chezmoi setup. Updating fetches only a fast-forward Git revision and
shows a diff; applying remains a separate action.

Shell startup files load shell-specific modules, which load shared settings.
Shared PATH functions deduplicate inherited entries without splitting paths
containing spaces. Global overrides are ignored local files. Project binaries
belong in approved direnv environments, `uv run` or `uvx`; temporary tools use
`with_path`. No project environment is automatically trusted.

Keep the existing NvChad settings and lock. Optional tool installation is a
separate command, shown before execution; editor plugin downloads happen when
the user starts Neovim. Tests use temporary homes and explicit XDG/state paths.
