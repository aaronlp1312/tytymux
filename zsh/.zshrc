# ---------- powerlevel10k instant prompt (keep first) ----------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
#  ZSHRC — TyDroid / Tyty toolkit (Termux)
# ============================================================================== 

# -------------------------- Shell Options --------------------------
setopt AUTO_CD NO_NOMATCH CORRECT CORRECT_ALL AUTO_MENU MENU_COMPLETE
setopt COMPLETE_IN_WORD EXTENDED_GLOB NO_CASE_GLOB HIST_IGNORE_DUPS
setopt SHARE_HISTORY HIST_IGNORE_SPACE

HISTFILE=$HOME/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
SPROMPT='zsh: correct %F{yellow}%R%f to %F{green}%r%f ? ([Y]es/[E]dit/[A]bort/[N]o) '

# -------------------------- Aliases --------------------------
alias nocor='nocorrect '
alias rm='nocorrect rm'
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias git='nocorrect git'
alias open='termux-open'
alias shared='cd "$TYSHARED"'
alias tysk='cd "$TYSHARED/scripts"'
alias tybk='cd "$TYSHARED/backups"'

# -------------------------- Completion Core --------------------------
zmodload zsh/complist 2>/dev/null || true
autoload -Uz compinit
mkdir -p "$HOME/.cache/zsh"
# Fast compinit: only check once a day to speed up Termux startup
if [[ -n "$HOME/.cache/zsh/zcompdump"(#qN.m-1) ]]; then
  compinit -C -d "$HOME/.cache/zsh/zcompdump"
else
  compinit -d "$HOME/.cache/zsh/zcompdump"
fi

bindkey '^I' expand-or-complete
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*' squeeze-slashes true

# -------------------------- Plugins & Theme --------------------------
# Autosuggestions
if [[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
  bindkey '^ ' autosuggest-accept  # Ctrl+Space
fi

# Themes
[[ -f "$HOME/.zsh-themes/td.zsh-theme" ]] && source "$HOME/.zsh-themes/td.zsh-theme"
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# Extra RC files
[[ -f "$HOME/.shell_rc_content" ]] && source "$HOME/.shell_rc_content"
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# ==============================================================================
# Paths / Environment
# ==============================================================================
export TYSHARED="/sdcard/termux-shared"
export PATH="$HOME/bin:$PATH:$TYSHARED/scripts"
export TYENV_DIR="${TYENV_DIR:-$HOME/environments/ty-25}"
alias tyenv='cd "$TYENV_DIR"'
alias ty='cd "$TYENV_DIR"'

# Clipboard helper
clipf() {
  if command -v termux-clipboard-set >/dev/null 2>&1; then
    termux-clipboard-set < "${1:-/dev/stdin}"
  else
    echo "termux-clipboard-set not found (install Termux:API)" >&2
    return 1
  fi
}

# ==============================================================================
# ADB — Tyty Reliable Mode (RESTORED)
# ==============================================================================
: "${ADB_HOST:=10.0.0.190}"
: "${ADB_PORT:=5555}"
export ADB_HOST ADB_PORT
unset ANDROID_SERIAL 2>/dev/null || true

_tadb_conf() { echo "$HOME/.config/tyty-adb.conf"; }
_tadb_mode() {
  local mode
  mode="$(grep -E '^MODE=' "$(_tadb_conf)" 2>/dev/null | tail -n 1 | cut -d= -f2)"
  [[ "$mode" == "mdns" ]] && echo "mdns" || echo "static"
}

_adb_bin() {
  command -v tyadb || command -v adb || echo ""
}

adbtry() {
  local A="$(_adb_bin)"
  [[ -z "$A" ]] && { echo "adb not found" >&2; return 127; }
  command "$A" "$@"
}

_adb_pick_serial() {
  [[ -n "${ANDROID_SERIAL:-}" ]] && { echo "$ANDROID_SERIAL"; return 0; }
  local list; list="$(adbtry devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1}' | grep -v '^emulator-' || true)"
  local count; count="$(echo "$list" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$count" == "1" ]]; then echo "$list"; return 0; fi
  if [[ -n "$ADB_HOST" ]]; then
    local match; match="$(echo "$list" | grep "^${ADB_HOST}:" | head -n 1 || true)"
    [[ -n "$match" ]] && { echo "$match"; return 0; }
  fi
  return 1
}

adbx() {
  local s; s="$(_adb_pick_serial)" || { echo "No unique device. Run: adbdevs" >&2; return 1; }
  adbtry -s "$s" "$@"
}

adbwho() {
  echo "ADB_BIN=$(_adb_bin)"
  echo "MODE=$(_tadb_mode)"
  echo "ADB_HOST=$ADB_HOST"
  if [[ -n "${ANDROID_SERIAL:-}" ]]; then echo "ANDROID_SERIAL=$ANDROID_SERIAL (pinned)"; else
    local s="$(_adb_pick_serial 2>/dev/null || true)"
    [[ -n "$s" ]] && echo "ANDROID_SERIAL=$s (auto)" || echo "ANDROID_SERIAL=(auto: none)"; fi
}

adbdevs() { adbtry devices -l 2>/dev/null | grep -v "emulator-"; }

adbrecover() {
  local mode="$(_tadb_mode)"
  adbtry kill-server >/dev/null 2>&1
  [[ "$mode" == "static" ]] && export ADB_MDNS_AUTO_CONNECT=""
  adbtry start-server >/dev/null 2>&1
  if [[ "$mode" == "mdns" ]]; then adbtry connect "adb-tls-connect" >/dev/null 2>&1
  else adbtry connect "${ADB_HOST}:${ADB_PORT}" >/dev/null 2>&1; fi
  adbdevs
}

adbhard() {
  adbtry kill-server >/dev/null 2>&1
  adbtry start-server >/dev/null 2>&1
  adbtry disconnect >/dev/null 2>&1
  adbtry connect "${1:-$ADB_HOST}:${2:-$ADB_PORT}"
  adbdevs
}

# ==============================================================================
# APK Helpers
# ==============================================================================
analyze_apk() {
  [[ -z "$1" ]] && return 1
  local base="${${1##*/}%.apk}"
  local out="$TYENV_DIR/apk_analysis/output/$base"
  mkdir -p "$out"
  command -v aapt >/dev/null && aapt dump badging "$1" > "$out/info.txt" 2>/dev/null
  echo "✓ analysis → $out"
}

# ==============================================================================
# F1–F8 Dashboard (Robust Bindings)
# ==============================================================================
f1() { clear; fastfetch 2>/dev/null || neofetch 2>/dev/null || uname -a; }
f2() { cd "$TYENV_DIR"; [[ -x "./tyty" ]] && ./tyty || echo "In: $TYENV_DIR"; }
f3() { echo "== adb status =="; adbwho; echo "\n== devices =="; adbdevs; echo "\n== recover =="; adbrecover; }
f5() { echo "== hard reset adb =="; adbhard; }
f7() {
  local CONF="$HOME/.config/tyty-adb.conf"
  mkdir -p "${CONF:h}"; touch "$CONF"
  if grep -q "MODE=mdns" "$CONF"; then sed -i 's/MODE=mdns/MODE=static/' "$CONF"; echo "Mode: Static";
  else sed -i 's/MODE=static/MODE=mdns/' "$CONF" || echo "MODE=mdns" >> "$CONF"; echo "Mode: mDNS"; fi
  adbrecover
}

# Bind F1..F8 to ZLE widgets for Termux
zmodload zsh/terminfo 2>/dev/null
_f1_w(){ zle -I; f1; zle redisplay }; zle -N _f1_w
_f2_w(){ zle -I; f2; zle redisplay }; zle -N _f2_w
_f3_w(){ zle -I; f3; zle redisplay }; zle -N _f3_w
_f5_w(){ zle -I; f5; zle redisplay }; zle -N _f5_w
_f7_w(){ zle -I; f7; zle redisplay }; zle -N _f7_w

bindkey "${terminfo[kf1]}" _f1_w 2>/dev/null || bindkey '^[OP' _f1_w
bindkey "${terminfo[kf2]}" _f2_w 2>/dev/null || bindkey '^[OQ' _f2_w
bindkey "${terminfo[kf3]}" _f3_w 2>/dev/null || bindkey '^[OR' _f3_w
bindkey "${terminfo[kf5]}" _f5_w 2>/dev/null || bindkey '^[[15~' _f5_w
bindkey "${terminfo[kf7]}" _f7_w 2>/dev/null || bindkey '^[[18~' _f7_w

# ==============================================================================
# MUST BE LAST
# ==============================================================================
if [[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
