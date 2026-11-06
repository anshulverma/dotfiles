---
name: zshrc-debug-startup-timing
description: ZSH startup timing instrumentation in .zshrc, gated by the ZSH_DEBUG_STARTUP env var or a ~/.zsh-debug-startup marker file
metadata:
  type: project
---

Read ~/.claude/LOCAL.md if present for local names and details.

`.zshrc` has per-section timing instrumentation gated behind `ZSH_DEBUG_STARTUP=1`. Uses glog format and writes to both stderr and a file.

**Log format:** `I<mmdd> <HH:MM:SS>.<usec> <pid> zshrc:<section>] cumulative=<ms>ms delta=<ms>ms`

**Log files:**
- Per-session: `/tmp/zshrc-startup-<pid>.log`
- Latest symlink: `/tmp/zshrc-startup-latest.log` (always points to most recent session)

`.zshenv` enables `ZSH_DEBUG_STARTUP=1` when `~/.zsh-debug-startup` exists (`touch ~/.zsh-debug-startup` to keep it on for a host).

To disable: `ZSH_DEBUG_STARTUP= zsh`, unset the variable, or remove the marker file. One-off use: `ZSH_DEBUG_STARTUP=1 zsh -lic exit`.

**Why:** User experienced slow shell startup on new remote dev hosts. Added 2026-05-18 to diagnose. Primary suspect is a system login script that can block up to 30s on first login waiting for the host's dotfile sync to finish — this runs before `.zshrc` so the timing logs only cover the `.zshrc` portion, not system login scripts. Glog format and file output added so AI agents can read and analyze the logs.

**How to apply:** If the user reports slow shell startup again, read `/tmp/zshrc-startup-latest.log` for the most recent timing data. The `.zshrc` timing only covers user config — system overhead (login scripts, profile.d) adds ~200ms for login shells and up to 30s if the dotfile sync hasn't completed. Use `time zsh -lic exit` vs the `[zshrc]` total to measure system vs user overhead.
