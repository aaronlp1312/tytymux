#!/usr/bin/env zsh
# ~/.zshrc.d/20-functions.zsh

inspect_pkg() {
    if [[ -z "$1" ]]; then
        echo "Usage: inspect_pkg <package.name>"
        return 1
    fi
    tyadb shell dumpsys package "$1" | grep -i version
}

alog() {
    if [[ -z "$1" ]]; then
        tyadb logcat -d | tail -n 50
    else
        tyadb logcat -d | grep -i "$1"
    fi
}
