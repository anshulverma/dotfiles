#!/usr/bin/env bash
# Dotfiles installer. Works on macOS, Ubuntu/Debian, and GitHub Codespaces.
# Idempotent — existing files are backed up to <path>.backup.<timestamp>.
#
# Usage:
#   ./install.sh              # install everything appropriate for this OS
#   ./install.sh --link-only  # only create symlinks, skip package install

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"

LINK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --link-only) LINK_ONLY=1 ;;
    -h|--help)
      sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 1 ;;
  esac
done

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

detect_os() {
  case "${OSTYPE:-}" in
    darwin*) echo macos ;;
    linux*)
      if [[ -r /etc/os-release ]] && grep -qiE 'ubuntu|debian' /etc/os-release; then
        echo debian
      else
        echo linux-other
      fi ;;
    *) echo unknown ;;
  esac
}

is_codespaces() { [[ -n "${CODESPACES:-}" ]]; }

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then return; fi
  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_packages_macos() {
  ensure_homebrew
  log "Installing packages via brew"
  brew install zsh tmux git vim
}

install_packages_debian() {
  log "Installing packages via apt"
  if [[ $EUID -eq 0 ]]; then
    apt-get update -y
    apt-get install -y zsh tmux git vim curl
  else
    sudo apt-get update -y
    sudo apt-get install -y zsh tmux git vim curl
  fi
}

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then return; fi
  log "Cloning TPM (tmux plugin manager)"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
}

# In Codespaces, also bootstrap the sibling repos we rely on. Keeps one
# dotfiles entry point responsible for turning a fresh codespace into a
# usable environment.
clone_and_install_emacs() {
  is_codespaces || return 0
  local dest="$HOME/workspace/emacs"
  if [[ ! -d "$dest/.git" ]]; then
    log "Cloning anshulverma/emacs -> $dest"
    mkdir -p "$(dirname "$dest")"
    git clone https://github.com/anshulverma/emacs.git "$dest"
  else
    log "emacs repo already present at $dest"
  fi
  ( cd "$dest" && ./install.sh ) || warn "emacs install.sh failed; continuing"
}

link_file() {
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    warn "source missing, skipping: $src"
    return
  fi
  if [[ -L "$dst" ]]; then
    # Already a symlink — replace it (idempotent).
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    warn "backing up existing $dst -> $dst.backup.$TS"
    mv "$dst" "$dst.backup.$TS"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  log "linked $dst -> $src"
}

link_all() {
  link_file "$DOTFILES_DIR/zsh/.zshrc"            "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/zsh/.zshenv"           "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/git/.gitconfig"        "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
  link_file "$DOTFILES_DIR/vim/.vimrc"            "$HOME/.vimrc"
  link_file "$DOTFILES_DIR/tmux/.tmux.conf"       "$HOME/.tmux.conf"
  link_file "$DOTFILES_DIR/tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
  link_file "$DOTFILES_DIR/readline/.inputrc"     "$HOME/.inputrc"
  link_file "$DOTFILES_DIR/gradle/gradle.properties" "$HOME/.gradle/gradle.properties"
}

import_iterm2_prefs() {
  local plist="$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist"
  [[ -f "$plist" ]] || return
  if ! command -v defaults >/dev/null 2>&1; then return; fi
  log "Importing iTerm2 preferences"
  defaults import com.googlecode.iterm2 "$plist"
}

# Codespaces grants password-less sudo, so we can switch the login shell
# without prompting. On other systems we just print instructions.
switch_login_shell_codespaces() {
  is_codespaces || return 0
  local zsh_bin
  zsh_bin="$(command -v zsh || true)"
  [[ -n "$zsh_bin" ]] || return 0
  case "${SHELL:-}" in *zsh) return 0 ;; esac
  log "Setting zsh as login shell (Codespaces)"
  sudo chsh -s "$zsh_bin" "${USER:-$(id -un)}" || warn "chsh failed; set shell manually"
}

main() {
  local os
  os="$(detect_os)"
  log "detected OS: $os (codespaces=$(is_codespaces && echo yes || echo no))"

  if [[ $LINK_ONLY -eq 0 ]]; then
    case "$os" in
      macos)  install_packages_macos ;;
      debian) install_packages_debian ;;
      *)      warn "unsupported OS for auto package install; continuing with symlinks only" ;;
    esac
    install_tpm
  fi

  link_all

  if [[ "$os" == macos && $LINK_ONLY -eq 0 ]]; then
    import_iterm2_prefs
  fi

  if [[ $LINK_ONLY -eq 0 ]]; then
    switch_login_shell_codespaces
    clone_and_install_emacs
  fi

  cat <<EOF

Done. Next steps:
  - Open a new zsh shell:        exec zsh
  - Set zsh as your login shell: chsh -s "\$(command -v zsh)"
  - Install tmux plugins:        start tmux, then press prefix + I (C-q I)

EOF
}

main
