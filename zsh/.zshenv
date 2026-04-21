# Environment variables — sourced for all zsh invocations (including non-interactive).
# Keep this file minimal; interactive configuration belongs in .zshrc.

export EDITOR="${EDITOR:-vim}"
export VISUAL="$EDITOR"
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
unset _DOTFILES_DIR
