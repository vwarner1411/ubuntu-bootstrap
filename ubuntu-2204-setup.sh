#!/usr/bin/env bash
# valerie.e.warner@gmail.com
# Ubuntu post-install bootstrap script
set -euo pipefail

###################################
# 0. Cleanup on exit               #
###################################
TMPDIR=""
cleanup() {
  [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
  # Remove the script if it’s a regular file (not /dev/fd/63 from curl|bash)
  if [[ -f "$0" ]]; then
    echo "Removing installer script $0"
    rm -- "$0"
  fi
}
trap cleanup EXIT

###################################
# 1. Sanity checks                #
###################################
if [[ $(id -u) -eq 0 ]]; then
  echo "Run this script as a sudo‑capable user, not root." >&2
  exit 1
fi

###################################
# 2. Package check & install      #
###################################
read -rp $'\nUpdate system and install required packages? [y/N] ' confirm
[[ ${confirm,,} == y* ]] || { echo "Aborted."; exit 1; }

MISSING_PKGS=()
need() { command -v "$1" &>/dev/null || MISSING_PKGS+=("${2:-$1}"); }
need curl curl
need rsync rsync
need jq   jq
need lsd  lsd
need btop btop
need nvim neovim
need zsh  zsh
need ddate ddate

if (( ${#MISSING_PKGS[@]} )); then
  echo "\nInstalling: ${MISSING_PKGS[*]}"
  sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}"
fi

###################################
# 3. Set default shell to zsh     #
###################################
if [[ $SHELL != "$(command -v zsh)" ]]; then
  echo "\nSwitching default shell to zsh…"
  chsh -s "$(command -v zsh)" "$USER"
fi

###################################
# 4. Oh‑My‑Zsh (git only if need) #
###################################
if [[ ! -d $HOME/.oh-my-zsh ]]; then
  if ! command -v git &>/dev/null; then
    echo "\nInstalling git (needed for Oh‑My‑Zsh)…"
    sudo apt install -y git
  fi
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

###################################
# 5. Fetch & deploy dotfiles repo #
###################################
GITHUB_DOTFILES="${1:-${GITHUB_DOTFILES:-}}"
if [[ -z "$GITHUB_DOTFILES" ]]; then
  echo "\nNo GITHUB_DOTFILES repo provided – skipping sync."
else
  echo "\nDownloading dotfiles tarball…"
  TMPDIR=$(mktemp -d)
  # Extract owner/repo path from any git URL variant
  RE_PATH=$(echo "$GITHUB_DOTFILES" | sed -E 's#(git@github.com:|https://github.com/)([^/.]+/[^/.]+).*#\2#')
  TAR_OK=false
  for branch in main master; do
    TAR_URL="https://github.com/${RE_PATH}/archive/refs/heads/${branch}.tar.gz"
    if curl -fsSL "$TAR_URL" -o "$TMPDIR/repo.tar.gz"; then
      TAR_OK=true; break; fi
  done
  if ! $TAR_OK; then
    echo "Failed to fetch repo tarball from GitHub" >&2; exit 1; fi

  tar -xzf "$TMPDIR/repo.tar.gz" -C "$TMPDIR"
  EXTRACT=$(find "$TMPDIR" -maxdepth 1 -type d -name '*-*' | head -n 1)
  echo "Rsync → $HOME (mirroring repo layout)…"
  rsync -a --delete --exclude ".git" "$EXTRACT/" "$HOME/"
fi

###################################
# 6. Done                         #
###################################
echo $'\nFinished!  Open a new terminal to enjoy your Dracula‑powered shell.\n   (This installer just self‑deleted to stay tidy.)'
