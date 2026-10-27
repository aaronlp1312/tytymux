#!/usr/bin/env zsh
# ~/.zshrc.d/30-tyty.zsh

# TYTY-AKITA Environment Initialization
export TYTY_WORKSPACE="$HOME/storage/downloads/TyTyWorkspace"

# Check if the tyadb daemon is running; if not, print a subtle warning
if ! pgrep -f "tyadb_daemon" > /dev/null; then
    print -P "%F{160}tyadb daemon is offline. Press F2 to connect or F5 to restart.%f"
else
    print -P "%F{046}tyadb daemon active.%f"
fi
