#!/usr/bin/env zsh
# ~/.zshrc.d/00-env.zsh

export PATH="$HOME/bin:$HOME/.local/bin:$PREFIX/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Define default editors
export EDITOR="nvim"
export VISUAL="nvim"
