# ==============================================================================
#  ZSHENV — Tydroid / K.Machine (Termux)
#  Loaded for every shell (interactive, non-interactive, scripts)
#  Keep this lean - only true environment vars go here
# ==============================================================================

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}"

# Editors
export EDITOR="nvim"
export VISUAL="nvim"

# Android SDK / NDK
export ANDROID_HOME="$PREFIX/opt/Android/sdk"
export ANDROID_NDK_HOME="$PREFIX/opt/android-ndk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-aarch64/bin"
