# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles intended to work on **macOS**, **Ubuntu/Debian**, and **GitHub Codespaces**. No build/test system — `install.sh` is the single entry point. It detects the OS, installs packages (brew on macOS, apt on Debian/Ubuntu), clones TPM, and symlinks every config file from this repo into `$HOME`.

## Layout

Each top-level directory corresponds to one tool; the files inside are symlinked to their canonical `$HOME` locations by `install.sh`.

- `zsh/` — `.zshrc` (interactive config, prompt, aliases, Homebrew shellenv) and `.zshenv` (PATH, EDITOR). Per-machine overrides belong in `~/.zshrc.local`, which `.zshrc` sources if present.
- `git/` — `.gitconfig` and `.gitignore_global`. `.gitconfig` includes `~/.gitconfig.local` at the end, so per-machine identity/signing overrides go there.
- `vim/` — minimal `.vimrc`. Swap/backup/undo go under `~/.vim/` (auto-created).
- `tmux/` — [gpakosz/.tmux](https://github.com/gpakosz/.tmux) distribution. `.tmux.conf` is the vendored upstream and should not be edited; personal bindings live in `.tmux.conf.local` under the `-- user customizations --` section (prefix `C-q`, pane bindings, etc.).
- `readline/.inputrc` — readline config (emacs mode, history-search on arrows and C-p/C-n).
- `iterm2/com.googlecode.iterm2.plist` — iTerm2 preferences. `install.sh` runs `defaults import` for this only on macOS.
- `gradle/gradle.properties` — symlinked to `~/.gradle/gradle.properties`.
- `bin/` — personal scripts merged in via `git subtree` from a separate repo (history preserved). `bin/scripts/` and `bin/applescripts/` are added to `$PATH` by `zsh/.zshenv`; don't add a separate install step for these.

## Things that are easy to get wrong

- The tmux prefix is `C-q`, not the default `C-b`. When reading/writing bindings in `tmux/.tmux.conf.local`, assume `C-q`.
- `.tmux.conf` (the vendored gpakosz file) is upstream — any personal change belongs in `.tmux.conf.local`, which sits beside it.
- Modern tmux (2.9+) requires `-style` for colours/attrs (e.g. `set -g status-style "bg=default,fg=white"`), not the old `-fg`/`-bg`/`-attr` trio. Don't reintroduce the deprecated syntax.
- The personal session-init block (`new -s avee …`, `htop`, `emacsclient`) in `.tmux.conf.local` is **commented out by default** — it requires htop/emacsclient and breaks on a fresh Codespaces/Ubuntu box. Only uncomment on machines that have those tools.
- `install.sh` is idempotent: existing real files at destinations get moved to `<path>.backup.<timestamp>`; existing symlinks are replaced silently. When debugging an install, look for `*.backup.*` files before assuming config was lost.
- Homebrew path differs by arch: `/opt/homebrew/bin/brew` on Apple Silicon, `/usr/local/bin/brew` on Intel. `.zshrc` and `install.sh` check both — do not hardcode one.
- `install.sh` deliberately does not run `chsh`. The post-install message tells the user to run it themselves; changing the login shell often needs a password and fails silently in CI/Codespaces.
- `zsh/.zshenv` derives the repo path from its own symlink via `${${(%):-%N}:A:h:h}` so `bin/scripts` gets on `PATH` regardless of where the repo is checked out. If you change the directory depth of `.zshenv` within the repo, update the number of `:h` strips.
