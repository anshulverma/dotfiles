# dotfiles

Personal dotfiles for macOS, Ubuntu/Debian, and GitHub Codespaces.

## Install

```sh
git clone https://github.com/anshulverma/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` detects the OS, installs packages (`brew` on macOS, `apt` on
Debian/Ubuntu), clones TPM, and symlinks every config into `$HOME`. It is
idempotent — existing files are backed up to `<path>.backup.<timestamp>`;
existing symlinks are replaced in place.

Flags:

- `./install.sh --link-only` — skip package install, only create symlinks.
- `./install.sh --help` — print usage.

Post-install:

- `exec zsh` — start zsh in the current terminal.
- `chsh -s "$(command -v zsh)"` — make zsh the login shell (needs your password).
- Start tmux and press `C-q I` to install tmux plugins via TPM.

## What's in here

| Path                   | Links to                           | Notes                                                        |
|------------------------|------------------------------------|--------------------------------------------------------------|
| `zsh/.zshrc`           | `~/.zshrc`                         | history, completion, vcs-aware prompt, OS-aware aliases      |
| `zsh/.zshenv`          | `~/.zshenv`                        | `PATH`, `EDITOR` — sourced for all zsh invocations           |
| `git/.gitconfig`       | `~/.gitconfig`                     | aliases, `zdiff3`, histogram diff                            |
| `git/.gitignore_global`| `~/.gitignore_global`              | OS / editor / env cruft                                      |
| `vim/.vimrc`           | `~/.vimrc`                         | sane defaults, persistent undo, system clipboard             |
| `tmux/.tmux.conf`      | `~/.tmux.conf`                     | [gpakosz/.tmux](https://github.com/gpakosz/.tmux) (vendored) |
| `tmux/.tmux.conf.local`| `~/.tmux.conf.local`               | personal bindings — prefix is `C-q`                          |
| `readline/.inputrc`    | `~/.inputrc`                       | emacs mode, history-search on arrows                         |
| `gradle/gradle.properties` | `~/.gradle/gradle.properties`  | enables gradle daemon                                        |
| `iterm2/com.googlecode.iterm2.plist` | (macOS `defaults import`) | iTerm2 preferences                                   |

## Per-machine overrides

Keep secrets and host-specific config out of this repo:

- `~/.zshrc.local` — sourced at the end of `.zshrc` if present.
- `~/.gitconfig.local` — included at the end of `.gitconfig` (work email,
  signing key, etc.).

## GitHub Codespaces

In your personal Codespaces settings, enable "Dotfiles" and point it at
this repo. Codespaces clones it and runs `install.sh` automatically for
every new codespace.

## Uninstall / rollback

Each symlink points at this repo, so removing the repo breaks the links.
Before re-linking, `install.sh` renames conflicting real files to
`<path>.backup.<timestamp>`; grep for `*.backup.*` in `$HOME` to restore.
