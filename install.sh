#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"

mkdir -p "$HOME_DIR/.zshrc.d" "$HOME_DIR/.config" "$HOME_DIR/.local/share" "$HOME_DIR/.cache" "$HOME_DIR/bin" "$HOME_DIR/.termux"

if [[ -f "$REPO_ROOT/termux/termux.properties" ]]; then
  cp "$REPO_ROOT/termux/termux.properties" "$HOME_DIR/.termux/termux.properties"
fi

if [[ -f "$REPO_ROOT/zsh/.zshenv" ]]; then
  cp "$REPO_ROOT/zsh/.zshenv" "$HOME_DIR/.zshenv"
fi

if [[ -f "$REPO_ROOT/zsh/.zshrc" ]]; then
  cp "$REPO_ROOT/zsh/.zshrc" "$HOME_DIR/.zshrc"
fi

for f in "$REPO_ROOT"/zsh/.zshrc.d/*.zsh; do
  [[ -f "$f" ]] || continue
  cp "$f" "$HOME_DIR/.zshrc.d/$(basename "$f")"
done

for f in "$REPO_ROOT"/bin/*; do
  [[ -f "$f" ]] || continue
  cp "$f" "$HOME_DIR/bin/$(basename "$f")"
  chmod 755 "$HOME_DIR/bin/$(basename "$f")"
done

if ! grep -q 'export PATH="\$HOME/bin:\$PATH"' "$HOME_DIR/.zshrc" 2>/dev/null; then
  printf '\n# tytymux\nexport PATH="$HOME/bin:$PATH"\n' >> "$HOME_DIR/.zshrc"
fi

# Optional shell bootstrap
if ! grep -q 'source ~/.zshrc' "$HOME_DIR/.zprofile" 2>/dev/null; then
  printf '\nsource ~/.zshrc\n' >> "$HOME_DIR/.zprofile"
fi

printf '\n[tytymux] Environment installed. Reload with: source ~/.zshrc\n'
