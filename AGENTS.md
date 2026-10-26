# Dotfiles contributor guide

- This repository is public. Version only reviewed nonsecret configs and references.
- Keep keys, tokens, auth caches, private SSH hosts, account data and machine-local overrides out of Git.
- `home/` is the static chezmoi source root. Preserve NvChad settings and lazy-lock.json; do not replace them with a starter distribution.
- Keep shell startup files thin. Shared PATH, aliases and helpers belong in `.config/shell`; zsh and bash must use the same PATH policy.
- Project-specific tools belong in uv/project environments or approved direnv files, not the global PATH. Never automatically allow a directory.
- Bootstrap downloads must use official sources, pinned versions and checksums. Do not execute a download before verification.
- Never apply files, install packages or fetch editor plugins on the developer's actual home as a test. Use explicit temporary destinations, XDG directories and manager state. Plugin integration runs only in disposable CI environments.
- Preserve existing files on conflicts unless replacement is explicitly requested and backed up. Avoid symlink traversal when installing tools/configs.
- Run shell/Python checks and isolated apply/idempotence tests before publishing. Update docs, lock metadata and generated installers together.
