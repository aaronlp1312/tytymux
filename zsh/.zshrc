# ==============================================================================
#  ZSHRC — Tydroid / K.Machine (Termux)
# ============================================================================== 

# Powerlevel10k instant prompt — must be first
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# MOTD
[[ -f ~/motd.sh ]] && source ~/motd.sh

# ==============================================================================
# ENVIRONMENT
# ==============================================================================
export TYSHARED="/sdcard/termux-shared"
export TYENV_DIR="${TYENV_DIR:-$HOME/environments/tyty-droid}"
export EDITOR="nvim"
export VISUAL="nvim"

pathadd() { case ":$PATH:" in *":$1:"*) ;; *) export PATH="$1:$PATH" ;; esac }
pathadd "$HOME/bin"
pathadd "$PREFIX/bin"
pathadd "$HOME/.local/bin"
pathadd "$HOME/.npm-global/bin"
pathadd "$HOME/.local/share/nvim/mason/bin"
pathadd "$TYSHARED/scripts"

# ==============================================================================
# HISTORY
# ==============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history hist_expire_dups_first hist_ignore_dups
setopt hist_ignore_space inc_append_history share_history

# ==============================================================================
# SHELL OPTIONS
# ==============================================================================
setopt AUTO_CD NO_NOMATCH CORRECT CORRECT_ALL AUTO_MENU MENU_COMPLETE
setopt COMPLETE_IN_WORD NO_CASE_GLOB EXTENDED_GLOB
SPROMPT='zsh: correct %F{yellow}%R%f to %F{green}%r%f ? ([Y]es/[E]dit/[A]bort/[N]o) '

# ==============================================================================
# ZLE / EDIT
# ==============================================================================
autoload -Uz edit-command-line zmv
zle -N edit-command-line
bindkey '^X^E' edit-command-line
bindkey '^Z' undo
bindkey '^Y' redo
bindkey ' ' magic-space

# ==============================================================================
# ZINIT
# ==============================================================================
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
typeset -gAH ZINIT
ZINIT[HOME_DIR]="$HOME/.local/share/zinit"
ZINIT[PLUGINS_DIR]="$ZINIT[HOME_DIR]/plugins"
ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]=1

zi ice wait"0" lucid; zi snippet OMZL::completion.zsh
zi ice wait"0" lucid; zi snippet OMZL::git.zsh
zi ice wait"0" lucid; zi snippet OMZL::key-bindings.zsh
zi ice wait"0" lucid; zi load zsh-users/zsh-autosuggestions
bindkey '^ ' autosuggest-accept
zi ice wait"0" lucid atinit"ZINIT[COMPLIST_HIGHLIGHT]='preview'"; zi load zdharma-continuum/fast-syntax-highlighting
zi ice wait"0" lucid; zi load zsh-users/zsh-completions
zi ice wait"0" lucid atload'bindkey "^I" menu-select; bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete'
zi load marlonrichert/zsh-autocomplete
zinit ice depth=1; zinit light romkatv/powerlevel10k

# ==============================================================================
# TOOLS
# ==============================================================================
eval "$(zoxide init zsh)"
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# Completion
zmodload zsh/complist 2>/dev/null || true
autoload -Uz compinit
mkdir -p "$HOME/.cache/zsh"
if [[ -n "$HOME/.cache/zsh/zcompdump"(#qN.m-1) ]]; then
  compinit -C -d "$HOME/.cache/zsh/zcompdump"
else
  compinit -d "$HOME/.cache/zsh/zcompdump"
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*' squeeze-slashes true

# ==============================================================================
# ADB — Tydroid Reliable Mode
# ==============================================================================
: "${ADB_HOST:=10.0.0.190}"
: "${ADB_PORT:=5555}"
export ADB_HOST ADB_PORT
unset ANDROID_SERIAL 2>/dev/null || true

_tadb_conf() { echo "$HOME/.config/tyty-adb.conf"; }
_tadb_mode() {
  local mode
  mode="$(grep -E '^MODE=' "$( _tadb_conf )" 2>/dev/null | tail -n 1 | cut -d= -f2)"
  [[ "$mode" == "mdns" ]] && echo "mdns" || echo "static"
}

_adb_bin() { command -v tyadb || command -v adb || echo ""; }

adbtry() {
  local A="$(_adb_bin)"
  [[ -z "$A" ]] && { echo "adb not found" >&2; return 127; }
  command "$A" "$@"
}

_adb_pick_serial() {
  [[ -n "${ANDROID_SERIAL:-}" ]] && { echo "$ANDROID_SERIAL"; return 0; }
  local list; list="$(adbtry devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1}' | grep -v '^emulator-' || true)"
  local count; count="$(echo "$list" | sed '/^$/d' | wc -l | tr -d ' ')"
  [[ "$count" == "1" ]] && { echo "$list"; return 0; }
  if [[ -f "$HOME/etc/tyadb.env" ]]; then
    local def_host; def_host=$(grep "TYADB_DEFAULT_HOST=" "$HOME/etc/tyadb.env" | cut -d'"' -f2)
    if [[ -n "$def_host" ]] && echo "$list" | grep -q "$def_host"; then
      echo "$def_host"; return 0
    fi
  fi
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
  if [[ -n "${ANDROID_SERIAL:-}" ]]; then echo "ANDROID_SERIAL=$ANDROID_SERIAL (pinned)"
  else
    local s="$(_adb_pick_serial 2>/dev/null || true)"
    [[ -n "$s" ]] && echo "ANDROID_SERIAL=$s (auto)" || echo "ANDROID_SERIAL=(auto: none)"
  fi
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
# F1-F8 DASHBOARD
# ==============================================================================
f1() { clear; fastfetch 2>/dev/null || neofetch 2>/dev/null || uname -a; }
f2() { cd "$TYENV_DIR"; [[ -x "./tyty" ]] && ./tyty || echo "In: $TYENV_DIR"; }
f3() { echo "== adb status =="; adbwho; echo "\n== devices =="; adbdevs; }
f4() { tyexport; }
f5() { echo "== adb recover =="; adbrecover; }
f6() { echo "== adb hard reset =="; adbhard; }
f7() {
  local CONF="$HOME/.config/tyty-adb.conf"
  mkdir -p "${CONF:h}"; touch "$CONF"
  if grep -q "MODE=mdns" "$CONF"; then sed -i 's/MODE=mdns/MODE=static/' "$CONF"; echo "Mode: Static"
  else sed -i 's/MODE=static/MODE=mdns/' "$CONF" || echo "MODE=mdns" >> "$CONF"; echo "Mode: mDNS"; fi
  adbrecover
}
f8() { command -v tyadb-shell &>/dev/null && tyadb-shell || adbx shell; }

zmodload zsh/terminfo 2>/dev/null
_f1_w(){ zle -I; f1; zle redisplay }; zle -N _f1_w
_f2_w(){ zle -I; f2; zle redisplay }; zle -N _f2_w
_f3_w(){ zle -I; f3; zle redisplay }; zle -N _f3_w
_f4_w(){ zle -I; f4; zle redisplay }; zle -N _f4_w
_f5_w(){ zle -I; f5; zle redisplay }; zle -N _f5_w
_f6_w(){ zle -I; f6; zle redisplay }; zle -N _f6_w
_f7_w(){ zle -I; f7; zle redisplay }; zle -N _f7_w
_f8_w(){ zle -I; f8; zle redisplay }; zle -N _f8_w

bindkey "${terminfo[kf1]}" _f1_w 2>/dev/null || bindkey '^[OP' _f1_w
bindkey "${terminfo[kf2]}" _f2_w 2>/dev/null || bindkey '^[OQ' _f2_w
bindkey "${terminfo[kf3]}" _f3_w 2>/dev/null || bindkey '^[OR' _f3_w
bindkey "${terminfo[kf4]}" _f4_w 2>/dev/null || bindkey '^[OS' _f4_w
bindkey "${terminfo[kf5]}" _f5_w 2>/dev/null || bindkey '^[[15~' _f5_w
bindkey "${terminfo[kf6]}" _f6_w 2>/dev/null || bindkey '^[[17~' _f6_w
bindkey "${terminfo[kf7]}" _f7_w 2>/dev/null || bindkey '^[[18~' _f7_w
bindkey "${terminfo[kf8]}" _f8_w 2>/dev/null || bindkey '^[[19~' _f8_w

# ==============================================================================
# ALIASES
# ==============================================================================
alias nocor='nocorrect '
alias rm='nocorrect rm'
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias git='nocorrect git'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias h='cd ~'
alias sd="cd /sdcard"
alias pf='cd "$PREFIX"'
alias ss="cd /sdcard/Pictures/Screenshots/"
alias ms="cd /sdcard/Movies"
alias dl="cd /sdcard/Download"
alias ds="cd /sdcard/Documents"
alias shared='cd "$TYSHARED"'
alias tysk='cd "$TYSHARED/scripts"'
alias tybk='cd "$TYSHARED/backups"'
alias tyenv='cd "$TYENV_DIR"'

alias q="exit"
alias c="clear"
alias cls="clear"
alias reload="source ~/.zshrc && rehash"
alias up='pkg update -y && pkg upgrade -y'
alias mkdir='mkdir -p'
alias open='termux-open'

alias v="nvim"
alias vi='nvim'
alias vim='nvim'
alias n='nvim'

alias g='git'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias py='python3'

alias psu="ps aux"
alias psg="ps aux | grep -i"
alias kill9="kill -9"
alias myip="curl ifconfig.me"
alias ports='netstat -tulpn'
alias largefile="du -h -x -s -- * | sort -r -h | head -20"

alias reload-termux="termux-reload-settings"
alias pd='proot-distro login ubuntu'
alias dts='~/environments/tyty-droid/bin/start-desktop.sh'

alias logo='$PREFIX/bin/logo'
alias crack='$PREFIX/bin/crack'
alias in-c='$PREFIX/bin/in-c'
alias out-c='$PREFIX/bin/out-c'
alias peek='$PREFIX/bin/peek'
alias host='$PREFIX/bin/host'
alias beam='$PREFIX/bin/beam'
alias scrub='$PREFIX/bin/scrub'
alias ninja="bash ~/ninja.sh"
alias rep="termux-clipboard-get >"
alias runclip='termux-clipboard-get > temp_script.py && python3 temp_script.py'

alias setlook='$PREFIX/bin/setlook'
alias setstyle='$PREFIX/bin/setstyle'
alias setname='$PREFIX/bin/setname'
alias setrepo='$PREFIX/bin/setrepo'
alias termux-change-repo="setrepo"

if command -v eza &>/dev/null; then
    alias ls="eza --icons"
    alias la="eza --icons -lgha --group-directories-first"
    alias l="eza --icons -lgha --group-directories-first"
    alias lt="eza --icons --tree"
    alias lta="eza --icons --tree -lgha"
    chpwd() { eza --icons -lgha --group-directories-first; }
fi

if command -v batcat &>/dev/null; then
    alias cat='batcat --theme OneHalfDark -p'
elif command -v bat &>/dev/null; then
    alias cat='bat --theme OneHalfDark -p'
fi

alias preview="fzf --preview='bat --color=always --style=numbers --theme OneHalfDark {}' --preview-window=down"
alias fnvim='nvim $(fzf -m --preview="bat --color=always --style=numbers --theme OneHalfDark {}" --preview-window=down)'
alias fcd="cd \$(find . -type d | fzf)"

# ==============================================================================
# FUNCTIONS
# ==============================================================================
mkcd()  { mkdir -p "$1" && cd "$1"; }
cpg()   { if [ -d "$2" ]; then cp "$1" "$2" && cd "$2" || return; else cp "$1" "$2"; fi }
mvg()   { if [ -d "$2" ]; then mv "$1" "$2" && cd "$2" || return; else mv "$1" "$2"; fi }
bring() { [[ -z "$1" ]] && return 1; cp -rf "$@" .; }
xport() { [[ -z "$1" ]] && return 1; cp -rf "$@" "/sdcard/Download/"; }

reveal() {
    printf "\n\033[1;36m[ NETWORK ]\033[0m\n"
    printf "\033[1;35mLocal  :: \033[1;37m%s\033[0m\n" "$(ifconfig wlan0 2>/dev/null | awk '/inet /{print $2}')"
    printf "\033[1;35mPublic :: \033[1;37m%s\033[0m\n" "$(curl -s https://api.ipify.org)"
    printf "\n"
}

ftext()   { rg -i "$1"; }
ft()      { rg -i "$1"; }
findbig() { fd -S +100M; }

copyclip() { termux-clipboard-set < "$1"; }
clipf() {
  command -v termux-clipboard-set >/dev/null 2>&1 || { echo "termux-clipboard-set not found" >&2; return 1; }
  termux-clipboard-set < "${1:-/dev/stdin}"
}

cp2clip() {
    [[ $# -eq 0 || ! -f "$1" ]] && return 1
    if command -v termux-clipboard-set >/dev/null; then cat "$1" | termux-clipboard-set
    elif command -v xclip >/dev/null; then cat "$1" | xclip -selection clipboard; fi
}

backup() {
    [[ -z "$1" ]] && return 1
    local b="${1}.backup.$(date +%Y%m%d_%H%M%S)"
    [[ -d "$1" ]] && cp -rv "$1" "$b" || cp -v "$1" "$b"
}

note() {
    local f="$HOME/.notes"
    [[ $# -eq 0 ]] && cat "$f" 2>/dev/null || echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$f"
}

extract() {
    [[ ! -f "$1" ]] && { echo "'$1' is not a valid file"; return 1; }
    case "$1" in
        *.tar.bz2)  tar xjf "$1"    ;;
        *.tar.gz)   tar xzf "$1"    ;;
        *.bz2)      bunzip2 "$1"    ;;
        *.rar)      unrar e "$1"    ;;
        *.gz)       gunzip "$1"     ;;
        *.tar)      tar xf "$1"     ;;
        *.tbz2)     tar xjf "$1"    ;;
        *.tgz)      tar xzf "$1"    ;;
        *.zip)      unzip "$1"      ;;
        *.Z)        uncompress "$1" ;;
        *.7z)       7z x "$1"       ;;
        *)          echo "Don't know how to extract '$1'" ;;
    esac
}

checksum() {
    [[ -z "$1" || ! -f "$1" ]] && return 1
    echo "  MD5:    $(md5sum "$1" | cut -d' ' -f1)"
    echo "  SHA1:   $(sha1sum "$1" | cut -d' ' -f1)"
    echo "  SHA256: $(sha256sum "$1" | cut -d' ' -f1)"
}

encrypt() { [[ -z "$1" ]] && return 1; openssl enc -aes-256-cbc -salt -in "$1" -out "${1}.enc"; }
decrypt() { [[ -z "$1" ]] && return 1; openssl enc -d -aes-256-cbc -in "$1" -out "${1%.enc}"; }

freplace() {
    [[ $# -ne 3 ]] && return 1
    grep -l "$1" "$3" 2>/dev/null || return 1
    read "REPLY?Continue with replacement? (y/N): "
    [[ $REPLY =~ ^[Yy]$ ]] && sed -i.bak "s/$1/$2/g" "$3"
}

duf() {
    local target="${1:-.}"
    du -h "$target"/* 2>/dev/null | sort -hr | head -20
}

fkill() {
    local tmpfile=$(mktemp)
    ps -eo user,pid,cmd --sort=-%mem | sed 1d | fzf --multi --reverse \
      --header=" Select processes to kill" \
      --preview 'ps -p {2} -o pid,user,%cpu,%mem,cmd' \
      --bind 'ctrl-s:toggle-sort' > "$tmpfile"
    [[ ! -s $tmpfile ]] && { rm -f "$tmpfile"; return; }
    while IFS= read -r line; do
        local pid=$(echo "$line" | awk '{print $2}')
        [[ -n "$pid" ]] && kill -TERM "$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null
    done < "$tmpfile"
    rm -f "$tmpfile"
}

tyexport() {
    local START_INPUT END_INPUT NOW LOWER UPPER OUTFILE
    START_INPUT=$(termux-dialog text -t "Start: hours ago (0-48)" | jq -r .text)
    END_INPUT=$(termux-dialog text -t "End: hours ago (0-48)" | jq -r .text)
    [[ -z "$START_INPUT" || "$START_INPUT" == "null" ]] && return 1
    NOW=$(date +%s)
    LOWER=$(( NOW - (START_INPUT * 3600) ))
    UPPER=$(( NOW - (END_INPUT * 3600) ))
    OUTFILE="$HOME/storage/downloads/history_export.txt"
    {
        echo "History: $START_INPUT to $END_INPUT hours ago"
        echo "Generated: $(date)"
        echo "=============================="
        awk -v min=$LOWER -v max=$UPPER '
          /^: [0-9]+/ {
            split($0, a, /[: ;]/); ts = a[3];
            if (ts >= min && ts <= max) { sub(/^: [0-9]+:[0-9]+;/, ""); print }
          }' ~/.zsh_history
    } > "$OUTFILE"
    termux-notification -t "History Saved" --content "Saved to downloads/history_export.txt"
}

analyze_apk() {
    [[ -z "$1" ]] && return 1
    local base="${${1##*/}%.apk}"
    local out="$TYENV_DIR/apk_analysis/output/$base"
    mkdir -p "$out"
    command -v aapt >/dev/null && aapt dump badging "$1" > "$out/info.txt" 2>/dev/null
    echo "-> analysis: $out"
}

setname() { [[ -z "$1" ]] && return 1; echo "$1" > ~/.termux_user; }
setlook()   { $PREFIX/bin/setlook; }
setstyle()  { $PREFIX/bin/setstyle; }

# ==============================================================================
# MODULAR CONFIGS (zshrc.d)
# ==============================================================================
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"
[[ -f "$HOME/.shell_rc_content" ]] && source "$HOME/.shell_rc_content"

if [[ -d ~/.zshrc.d ]]; then
    for file in ~/.zshrc.d/*.zsh(N); do
        [[ -f "$file" ]] && source "$file"
    done
fi

# ==============================================================================
# PROMPT
# ==============================================================================
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
