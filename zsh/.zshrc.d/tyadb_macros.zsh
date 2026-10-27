#!/usr/bin/env zsh
# ~/.zshrc.d/tyadb_macros.zsh

bindkey -s '^[OP'   'tyadb shell dumpsys\n'
bindkey -s '^[OQ'   'tyadb connect\n'
bindkey -s '^[OR'   'tyadb shell top\n'
bindkey -s '^[OS'   'tyadb logcat\n'
bindkey -s '^[[15~' 'tyadb kill-server && tyadb start-server\n'
bindkey -s '^[[17~' 'boss --status\n'
bindkey -s '^[[18~' 'nvim\n'
bindkey -s '^[[19~' 'cd ~/bin && eza -la\n'
