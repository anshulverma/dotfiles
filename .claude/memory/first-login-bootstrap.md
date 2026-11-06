---
name: first-login-bootstrap
description: How a fresh remote dev host bootstraps dotfiles; the trailing-& bug that broke first login and the synchronous-on-first-login fix
metadata:
  type: project
---

Read ~/.claude/LOCAL.md if present for local names and details.

On a fresh remote dev host, the home-directory sync tool recreates `~/.zshrc` /
`~/.zshenv` as **symlinks into `~/workspace/dotfiles`**, but that repo is only
cloned by the sync tool's post-pull hook. Two bootstrap files live OUTSIDE this
repo as real, sync-tracked home files (confirmed in the sync tool's metadata):

- `~/.zprofile` — login-only trigger for the hook.
- the post-pull hook — clones `~/workspace/dotfiles` (+ emacs) and runs `install.sh`.

**The bug:** `~/.zprofile` ran the hook with a trailing `&`, so the clone ran in
the background and the first interactive shell started before it finished:
dangling symlinks → default `~%` prompt, `cat ~/.zshrc` fails, and `tmux` dies
with `missing or unsuitable terminal: xterm-ghostty`. It only worked on the
*second* shell (e.g. the one tmux spawns), by which time the background clone
had finished.

**The fix (2026-06-23):**
- `~/.zprofile`: when `~/workspace/dotfiles` is missing, run the hook
  **synchronously** (block first login until clone+install done) and `. ~/.zshenv`
  after (it was skipped while the symlink dangled); once present, run detached.
- post-pull hook: dotfiles stays foreground (fast); the heavy emacs clone/build
  runs detached via `setsid … &`.
- `install.sh`: skips apt when zsh/tmux/git/vim already exist (they do on such a
  host — apt was the slow part), and installs vendored `ghostty/xterm-ghostty.terminfo`
  via `tic -x` into `~/.terminfo` (always, even `--link-only`) so tmux/ssh from
  Ghostty work without Ghostty installed on the host.

**Why:** the host is functional from the very first prompt instead of needing a
second shell. Related: a system login script waits for the host's dotfile sync
but did not cover the backgrounded post-pull clone — see
[[zshrc-debug-startup-timing]].

**How to apply:** if first login on a new host is broken again, check the
trailing `&` in `~/.zprofile` and whether `~/workspace/dotfiles` exists, then
read the post-pull hook's log.
