# Environment variables — sourced for all zsh invocations (including non-interactive).
# Keep this file minimal; interactive configuration belongs in .zshrc.

# Enable zshrc startup timing: auto-enabled on ondemand devservers,
# or persistently via "touch ~/.zsh-debug-startup".
if [[ -z "${ZSH_DEBUG_STARTUP+x}" ]]; then
  if [[ -f "$HOME/.zsh-debug-startup" ]] || [[ -d /ondemand ]]; then
    export ZSH_DEBUG_STARTUP=1
  fi
fi

if [[ -n "${ZSH_DEBUG_STARTUP:-}" ]]; then
  zmodload zsh/datetime
  typeset -gF _zshenv_t0=$EPOCHREALTIME
  typeset -g _zshrc_logfile="/tmp/zshrc-startup-$$.log"
  : >| "$_zshrc_logfile"
fi
export PAGER="${PAGER:-less}"
export LESS='-R -i -M -x4'
export LANG="${LANG:-en_US.UTF-8}"

# User-local bin directories on PATH (deduped via typeset -U in .zshrc).
typeset -U path PATH

# Scripts from this repo's bin/ dir. DOTFILES_DIR is resolved from the symlink
# at ~/.zshenv back to the repo checkout.
_DOTFILES_DIR="${${(%):-%N}:A:h:h}"

path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$_DOTFILES_DIR/bin/scripts"
  "$_DOTFILES_DIR/bin/applescripts"
  $path
)

# $EDITOR must be a single executable: some tools exec it directly without
# word-splitting. The wrapper in bin/scripts handles the emacsclient flags.
export EDITOR="$_DOTFILES_DIR/bin/scripts/emacseditor"
export VISUAL="$EDITOR"

unset _DOTFILES_DIR

if [[ -n "${ZSH_DEBUG_STARTUP:-}" ]]; then
  typeset -gF _zshenv_done=$EPOCHREALTIME
  local _d=$(( (_zshenv_done - _zshenv_t0) * 1000 ))
  local _sec=${_zshenv_done%.*} _frac=${_zshenv_done#*.}
  local _ts; _ts=$(strftime '%m%d %H:%M:%S' $_sec)
  printf 'I%s.%s %d zshenv:done] duration=%.1fms\n' \
    "$_ts" "${_frac[1,6]}" $$ $_d >>| "$_zshrc_logfile"
fi
