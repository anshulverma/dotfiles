# Interactive zsh configuration.

# -- platform detection --------------------------------------------------------
case "$OSTYPE" in
  darwin*) IS_MAC=1 ;;
  linux*)  IS_LINUX=1 ;;
esac
[[ -n "${CODESPACES:-}" ]] && IS_CODESPACES=1

# -- homebrew (macOS) ----------------------------------------------------------
if [[ -n "${IS_MAC:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# -- history -------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
       HIST_VERIFY EXTENDED_HISTORY INC_APPEND_HISTORY

# -- directory navigation ------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# -- completion ----------------------------------------------------------------
autoload -Uz compinit
# Speed up compinit by only security-checking the dump once a day.
if [[ -n $(find "${ZDOTDIR:-$HOME}/.zcompdump"(Nmh+24) 2>/dev/null) ]]; then
  compinit
else
  compinit -C
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' '+l:|=* r:|=*'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' group-name ''

# -- keybindings ---------------------------------------------------------------
# Match the emacs-style bindings from .inputrc.
bindkey -e
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward
bindkey "${terminfo[kcuu1]:-^[[A}" history-search-backward
bindkey "${terminfo[kcud1]:-^[[B}" history-search-forward

# -- prompt --------------------------------------------------------------------
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' %F{magenta}(%b)%f'
zstyle ':vcs_info:*' enable git
precmd() { vcs_info }
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f${vcs_info_msg_0_}
%(?.%F{green}.%F{red})❯%f '

# -- aliases -------------------------------------------------------------------
if ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'
else
  alias ls='ls -G'  # BSD ls (macOS default)
fi
alias ll='ls -lh'
alias la='ls -lAh'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gco='git checkout'
alias gcb='git checkout -b'

# -- safety nets ---------------------------------------------------------------
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias rmf='rm -f'
alias cpf='cp -f'
alias mvf='mv -f'
alias mkdir='mkdir -p'

# -- shortcuts -----------------------------------------------------------------
alias h='history'
alias j='jobs -l'
alias du='du -kh'
alias df='df -kTh 2>/dev/null || df -kh'

# -- tmux ----------------------------------------------------------------------
alias tmuxa='tmux -2 a'
tmw() { tmux split-window -dh "$*"; }   # run a command in a new split

# -- docker --------------------------------------------------------------------
alias docker-rm-all='docker rm $(docker ps -a -q)'
alias docker-kill-all='docker kill $(docker ps -a -q)'
docker-exec()    { docker exec -it "$(docker_container_id "$1")" bash; }
docker-kill()    { docker kill      "$(docker_container_id "$1")"; }
docker-inspect() { docker inspect   "$(docker_container_id "$1")"; }
docker-ip()      { docker inspect -f '{{.NetworkSettings.IPAddress}}' "$@"; }

# -- misc ----------------------------------------------------------------------
httph() { curl -iksD - "$1" -o /dev/null; }  # dump headers for a URL

# macOS-only helpers
if [[ -n "${IS_MAC:-}" ]]; then
  alias sleep-computer='osascript -e "tell application \"Finder\" to sleep"'
  chrome() { open -a 'Google Chrome' "${1:-https://google.com}"; }
fi

# -- local overrides -----------------------------------------------------------
# Per-machine settings (secrets, work-specific aliases) go in ~/.zshrc.local.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
