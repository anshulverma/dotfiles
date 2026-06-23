---
name: od-first-login-bootstrap
description: How a fresh Meta OD bootstraps dotfiles; the trailing-& bug that broke first login and the synchronous-on-first-login fix
metadata:
  type: project
---

On a fresh Meta on-demand server, dotsync recreates `~/.zshrc` / `~/.zshenv` as
**symlinks into `~/workspace/dotfiles`**, but that repo is only cloned by the
dotsync2 post-pull hook. Two bootstrap files live OUTSIDE this repo as real,
dotsync-tracked home files (confirmed in `~/.dotsync/metadata.json` checksums):

- `~/.zprofile` — login-only trigger for the hook.
- `~/.config/dotsync2/post-pull.sh` — clones `~/workspace/dotfiles` (+ emacs) and runs `install.sh`.

**The bug:** `~/.zprofile` was `… post-pull.sh &>/tmp/… &` — the trailing `&`
ran the clone in the background, so the first interactive shell started before
the clone finished: dangling symlinks → default `~%` prompt, `cat ~/.zshrc`
fails, and `tmux` dies with `missing or unsuitable terminal: xterm-ghostty`.
It only worked on the *second* shell (e.g. the one tmux spawns), by which time
the background clone had finished.

**The fix (2026-06-23):**
- `~/.zprofile`: when `~/workspace/dotfiles` is missing, run post-pull
  **synchronously** (block first login until clone+install done) and `. ~/.zshenv`
  after (it was skipped while the symlink dangled); once present, run detached.
- `~/.config/dotsync2/post-pull.sh`: dotfiles stays foreground (fast); the heavy
  emacs clone/build runs detached via `setsid … &`.
- `install.sh`: skips apt when zsh/tmux/git/vim already exist (they do on an OD —
  apt was the slow part), and installs vendored `ghostty/xterm-ghostty.terminfo`
  via `tic -x` into `~/.terminfo` (always, even `--link-only`) so tmux/ssh from
  Ghostty work without Ghostty installed on the host.

**Why:** the OD is functional from the very first prompt instead of needing a
second shell. Related: the system `/etc/shell-login.d/10-wait-for-dotfiles.sh`
waits on `dotfiles.target` but did not cover the backgrounded post-pull clone —
see [[zshrc-debug-startup-timing]].

**How to apply:** if first login on a new OD is broken again, check the trailing
`&` in `~/.zprofile` and whether `~/workspace/dotfiles` exists; the post-pull log
is `/tmp/dotsync2-post-pull.log` (emacs: `/tmp/dotsync2-post-pull-emacs.log`).
