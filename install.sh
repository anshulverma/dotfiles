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
  # Meta on-demand servers (and most provisioned boxes) already ship zsh/tmux/
  # git/vim. apt-get update+install there is slow and needs sudo — on a fresh OD
  # that delay is what makes the first login race the dotfiles clone. Skip it
  # entirely when the core tools are already present.
  if command -v zsh tmux git vim >/dev/null 2>&1; then
    log "core packages already present (zsh/tmux/git/vim); skipping apt"
    return
  fi
  log "Installing packages via apt"
  if [[ $EUID -eq 0 ]]; then
    apt-get update -y
    apt-get install -y zsh tmux git vim curl
  else
    sudo apt-get update -y
    sudo apt-get install -y zsh tmux git vim curl
  fi
}

# Install the vendored xterm-ghostty terminfo into ~/.terminfo so terminals
# launched from Ghostty (tmux, ssh) don't fail with "missing or unsuitable
# terminal: xterm-ghostty" on hosts where Ghostty itself isn't installed.
# User-level (~/.terminfo) so it needs no sudo; no-op if already known.
install_terminfo() {
  local src="$DOTFILES_DIR/ghostty/xterm-ghostty.terminfo"
  [[ -f "$src" ]] || return 0
  command -v tic >/dev/null 2>&1 || { warn "tic not found; skipping terminfo install"; return 0; }
  if infocmp -x xterm-ghostty >/dev/null 2>&1; then return 0; fi
  log "Installing xterm-ghostty terminfo -> ~/.terminfo"
  tic -x -o "$HOME/.terminfo" "$src" 2>/dev/null || warn "tic failed for $src"
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
  link_file "$DOTFILES_DIR/ghostty/config"        "$HOME/.config/ghostty/config"
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
  install_terminfo   # always — fast, no sudo, and unrelated to package install

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
