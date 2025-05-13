#!/usr/bin/env bash
# valerie.e.warner@gmail.com
# Ubuntu post-install bootstrap script
set -euo pipefail

TMPDIR=""
cleanup() {
  [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
  [[ -f "$0" ]] && { echo "Removing installer script $0"; rm -- "$0"; }
}
trap cleanup EXIT

###################################
# 1. Privilege check              #
###################################
if [[ $(id -u) -eq 0 ]]; then
  echo "Run this script as a sudo-capable user, not root." >&2
  exit 1
fi

###################################
# 2. Package check / install      #
###################################
read -rp $'\nUpdate package index and install missing packages? [y/N] ' confirm
[[ ${confirm,,} == y* ]] || { echo "Aborted."; exit 1; }

MISSING_PKGS=()
need() { command -v "$1" &>/dev/null || MISSING_PKGS+=("${2:-$1}"); }
need curl curl
need rsync rsync
need jq jq
need lsd lsd
need btop btop
need nvim neovim
need zsh zsh
need ddate ddate

if (( ${#MISSING_PKGS[@]} )); then
  sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}"
fi

###################################
# 3. Default shell → zsh          #
###################################
if [[ $SHELL != $(command -v zsh) ]]; then
  echo "Setting default shell to zsh…"
  chsh -s "$(command -v zsh)" "$USER"
fi

###################################
# 4. Ensure Oh‑My‑Zsh             #
###################################
ensure_ohmyzsh() {
  command -v git &>/dev/null || { echo "Installing git for Oh‑My‑Zsh…"; sudo apt install -y git; }
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh‑My‑Zsh…"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Updating existing Oh‑My‑Zsh…"
    git -C "$HOME/.oh-my-zsh" pull --quiet --ff-only || {
      echo "Oh‑My‑Zsh repo damaged – reinstalling…";
      rm -rf "$HOME/.oh-my-zsh"
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    }
  fi
}
ensure_ohmyzsh

###################################
# 5. Fetch & copy repo files      #
###################################
GITHUB_DOTFILES="${1:-${GITHUB_DOTFILES:-}}"
if [[ -n "$GITHUB_DOTFILES" ]]; then
  echo "Downloading dotfiles repo archive…"
  TMPDIR=$(mktemp -d)
  RE_PATH=$(echo "$GITHUB_DOTFILES" | sed -E 's#(git@github.com:|https://github.com/)([^/.]+/[^/.]+).*#\2#')
  TAR_OK=false
  for b in main master; do
    TAR_URL="https://github.com/${RE_PATH}/archive/refs/heads/${b}.tar.gz"
    curl -fsSL "$TAR_URL" -o "$TMPDIR/repo.tar.gz" && { TAR_OK=true; break; }
  done
  $TAR_OK || { echo "Failed to fetch repo archive" >&2; exit 1; }
  tar -xzf "$TMPDIR/repo.tar.gz" -C "$TMPDIR"
  SRC=$(find "$TMPDIR" -maxdepth 1 -type d -name '*-*' | head -n 1)
  echo "Copying repo contents into $HOME (non‑destructive)…"
  rsync -a --update --progress --exclude ".git" "$SRC/" "$HOME/"
else
  echo "No GITHUB_DOTFILES provided – skipping dotfiles sync."
fi

###################################
# 6. Ensure Oh‑My‑Zsh plugins     #
###################################
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_plugin() { [[ -d "$2" ]] || git clone --depth 1 "$1" "$2"; }
command -v git &>/dev/null || sudo apt install -y git
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_plugin https://github.com/zsh-users/zsh-autosuggestions.git        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_plugin https://github.com/zsh-users/zsh-completions.git            "$ZSH_CUSTOM/plugins/zsh-completions"
clone_plugin https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git "$ZSH_CUSTOM/plugins/autoupdate"

###################################
# 7. Done                         #
###################################
echo "Setup complete. Open a new terminal to start using your configured environment."
