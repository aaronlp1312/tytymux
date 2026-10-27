# Tytmux

Recovered Termux + TyADB/Tydroid shell environment for a fresh Android tablet.

This repo captures a portable shell stack built around:

- zsh + Powerlevel10k
- zinit plugin management
- TyADB/Tydroid aliases and helper functions
- ADB-oriented recovery and device helpers
- custom F1-F8 key mapping
- a lightweight `tyty` launcher and `boss` share router

## Layout

- `install.sh` – installs the environment into a fresh Termux home
- `bin/tyty` – launcher for the TyTydroid environment
- `bin/boss` – file/url/text share router
- `termux/termux.properties` – keyboard/UI config
- `zsh/.zshenv` – environment variables
- `zsh/.zshrc` – shell config
- `zsh/.zshrc.d/*.zsh` – modular shell additions

## Quick install

```bash
cd ~
git clone https://github.com/aaronlp1312/tytymux.git
cd tytymux
bash install.sh
```

## Notes

This project is intended to restore a developer shell environment for Android/Termux work, especially around TyADB, wireless ADB, and local device automation. It is designed as a shell layer and should be paired with appropriate Android workflow permissions and trusted device control practices.
