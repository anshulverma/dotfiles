---
name: zshrc-debug-startup-timing
description: ZSH startup timing instrumentation in .zshrc, gated by ZSH_DEBUG_STARTUP env var, auto-enabled on ondemand devservers
metadata:
  type: project
---

`.zshrc` has per-section timing instrumentation gated behind `ZSH_DEBUG_STARTUP=1`. Each major section logs cumulative and delta time to stderr in the format `[zshrc] <cumulative>ms (+<delta>ms)  <section>`.

`.zshenv` auto-enables `ZSH_DEBUG_STARTUP=1` on ondemand devservers (detected via `/ondemand` directory existence).

To disable: `ZSH_DEBUG_STARTUP= zsh` or unset the variable. To use on non-ondemand machines: `ZSH_DEBUG_STARTUP=1 zsh -lic exit`.

**Why:** User experienced slow shell startup on new ondemand servers. Added 2026-05-18 to diagnose. Primary suspect is the system-level `/etc/shell-login.d/10-wait-for-dotfiles.sh` which can block up to 30s on first login waiting for `dotfiles.target` — this runs before `.zshrc` so the timing logs only cover the `.zshrc` portion, not system login scripts.

**How to apply:** If the user reports slow shell startup again, first check whether the timing logs are still present. The `.zshrc` timing only covers user config — system overhead (login scripts, profile.d) adds ~200ms for login shells and up to 30s if `dotfiles.target` hasn't completed. Use `time zsh -lic exit` vs the `[zshrc]` total to measure system vs user overhead.
