# Interactive zsh configuration.

# -- startup timing (set ZSH_DEBUG_STARTUP=1 to enable) -----------------------
if [[ -n "${ZSH_DEBUG_STARTUP:-}" ]]; then
  zmodload zsh/datetime
  _zshrc_t0=$EPOCHREALTIME
  _zshrc_ts=$_zshrc_t0
  _zshrc_logfile="/tmp/zshrc-startup-$$.log"
  : >| "$_zshrc_logfile"

  # emit a header with shell invocation context
  {
    local _flags=""
    [[ -o interactive ]] && _flags+="i" || _flags+="-"
    [[ -o login ]]       && _flags+="l" || _flags+="-"
    print -r -- "# pid=$$ ppid=$PPID uid=$UID flags=$_flags"
    local _tty; _tty=$(tty 2>/dev/null) || _tty="not a tty"
    print -r -- "# tty=$_tty"
    print -r -- "# term=$TERM term_program=${TERM_PROGRAM:-unset} lang=${LANG:-unset}"
    [[ -n "${SSH_CONNECTION:-}" ]] && print -r -- "# ssh=$SSH_CONNECTION"
    local _parent_cmd
    _parent_cmd=$(ps -o comm= -p $PPID 2>/dev/null) || _parent_cmd="unknown"
    print -r -- "# parent_cmd=$_parent_cmd"
    print -r -- "# argv=$ZSH_ARGZERO $@"
  } >>| "$_zshrc_logfile"

  _zshrc_log() {
    local now=$EPOCHREALTIME
    local cumul_ms=$(( (now - _zshrc_t0) * 1000 ))
    local delta_ms=$(( (now - _zshrc_ts) * 1000 ))
    local sec=${now%.*}
    local frac=${now#*.}
    local ts
    ts=$(strftime '%m%d %H:%M:%S' $sec)
    local usec=${frac[1,6]}
    local line
    printf -v line 'I%s.%s %d zshrc:%s] cumulative=%.1fms delta=%.1fms' \
      "$ts" "$usec" $$ "$1" $cumul_ms $delta_ms
    print -r -- "$line" >&2
    print -r -- "$line" >>| "$_zshrc_logfile"
    _zshrc_ts=$now
  }

  _zshrc_exit_signal=""
  for _sig in HUP TERM QUIT PIPE; do
    eval "TRAP${_sig}() { _zshrc_exit_signal=$_sig; exit \$(( 128 + \$1 )); }"
  done
  unset _sig

  zshexit() {
    local rc=$?
    [[ -z "$_zshrc_logfile" ]] && return
    local now=$EPOCHREALTIME
    local sec=${now%.*} frac=${now#*.}
    local ts; ts=$(strftime '%m%d %H:%M:%S' $sec)
    local info="exit_code=$rc"
    [[ -n "$_zshrc_exit_signal" ]] && info+=" signal=SIG$_zshrc_exit_signal"
    local dur_s=$(( now - _zshrc_t0 ))
    if (( dur_s >= 3600 )); then
      info+=$(printf ' session=%dh%dm' $(( dur_s / 3600 )) $(( dur_s % 3600 / 60 )))
    elif (( dur_s >= 60 )); then
      info+=$(printf ' session=%dm%ds' $(( dur_s / 60 )) $(( dur_s % 60 )))
    else
      info+=$(printf ' session=%.1fs' $dur_s)
    fi
    printf 'I%s.%s %d zshrc:exit] %s\n' "$ts" "${frac[1,6]}" $$ "$info" >>| "$_zshrc_logfile"
  }
fi

# -- platform detection --------------------------------------------------------
case "$OSTYPE" in
  darwin*) IS_MAC=1 ;;
  linux*)  IS_LINUX=1 ;;
esac
[[ -n "${CODESPACES:-}" ]] && IS_CODESPACES=1
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "platform detection"

# -- homebrew (macOS) ----------------------------------------------------------
if [[ -n "${IS_MAC:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "homebrew"

# -- history -------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
       HIST_VERIFY EXTENDED_HISTORY INC_APPEND_HISTORY
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "history"

# -- directory navigation ------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "directory navigation"

# -- completion ----------------------------------------------------------------
autoload -Uz compinit
# -u: use completions from insecure dirs without prompting (fresh Ubuntu /usr/share/zsh
#     often has group-writable dirs that would otherwise prompt at every login).
# Rebuild the dump at most once a day.
if [[ -n $(find "${ZDOTDIR:-$HOME}/.zcompdump"(Nmh+24) 2>/dev/null) ]]; then
  compinit -u
else
  compinit -C -u
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' '+l:|=* r:|=*'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' group-name ''
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "completion"

# -- keybindings ---------------------------------------------------------------
# Match the emacs-style bindings from .inputrc.
bindkey -e
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward
bindkey "${terminfo[kcuu1]:-^[[A}" history-search-backward
bindkey "${terminfo[kcud1]:-^[[B}" history-search-forward
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "keybindings"

# -- prompt --------------------------------------------------------------------
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' %F{magenta}(%b)%f'
zstyle ':vcs_info:*' enable git
precmd() { vcs_info }
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f${vcs_info_msg_0_}
%(?.%F{green}.%F{red})❯%f '
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "prompt"

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
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "aliases"

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
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "shortcuts"

# -- tmux ----------------------------------------------------------------------
alias tmuxa='tmux -2 a'
tmw() { tmux split-window -dh "$*"; }   # run a command in a new split

# Auto-attach to tmux on SSH login when a session exists.
# Guards: interactive shell, SSH login, not already inside tmux, tmux installed.
if [[ $- == *i* ]] && [[ -n "${SSH_CONNECTION:-}" ]] && [[ -z "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  if tmux list-sessions >/dev/null 2>&1; then
    exec tmux -2 attach
  fi
fi
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "tmux"

# -- docker --------------------------------------------------------------------
alias docker-rm-all='docker rm $(docker ps -a -q)'
alias docker-kill-all='docker kill $(docker ps -a -q)'
docker-exec()    { docker exec -it "$(docker_container_id "$1")" bash; }
docker-kill()    { docker kill      "$(docker_container_id "$1")"; }
docker-inspect() { docker inspect   "$(docker_container_id "$1")"; }
docker-ip()      { docker inspect -f '{{.NetworkSettings.IPAddress}}' "$@"; }
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "docker"

# -- misc ----------------------------------------------------------------------
httph() { curl -iksD - "$1" -o /dev/null; }  # dump headers for a URL

# macOS-only helpers
if [[ -n "${IS_MAC:-}" ]]; then
  alias sleep-computer='osascript -e "tell application \"Finder\" to sleep"'
  chrome() { open -a 'Google Chrome' "${1:-https://google.com}"; }
fi
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "misc"

# -- local overrides -----------------------------------------------------------
# Per-machine settings (secrets, work-specific aliases) go in ~/.zshrc.local.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
[[ -n "${ZSH_DEBUG_STARTUP:-}" ]] && _zshrc_log "local overrides"

# -- startup timing teardown ---------------------------------------------------
if [[ -n "${ZSH_DEBUG_STARTUP:-}" ]]; then
  _zshrc_log "zshrc complete"
  ln -sf "$_zshrc_logfile" /tmp/zshrc-startup-latest.log
  unfunction _zshrc_log
  unset _zshrc_ts
fi
