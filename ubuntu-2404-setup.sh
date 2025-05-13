#!/usr/bin/env bash
# valerie.e.warner@gmail.com
# Ubuntu post-install bootstrap script
set -euo pipefail

#############################
# Colour helpers            #
#############################
if [[ -t 1 ]]; then
  BOLD="$(tput bold)"; RESET="$(tput sgr0)"
  BLUE="$(tput setaf 4)"; GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"; RED="$(tput setaf 1)"
else
  BOLD=""; RESET=""; BLUE=""; GREEN=""; YELLOW=""; RED=""
fi
info()    { echo -e "${BLUE}${BOLD}▶${RESET} $*"; }
ok()      { echo -e "${GREEN}${BOLD}✔${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}!${RESET} $*"; }
fail()    { echo -e "${RED}${BOLD}✖${RESET} $*"; exit 1; }

TMPDIR=""
cleanup() { [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"; }
trap cleanup EXIT

#############################
# 1. Privilege check        #
#############################
if [[ $(id -u) -eq 0 ]]; then fail "Do not run as root. Use a regular user with sudo."; fi

#############################
# 2. Packages               #
#############################
read -rp "${BOLD}Update APT and install required packages? [y/N] ${RESET}" confirm
[[ ${confirm,,} == y* ]] || fail "Aborted by user."

need_pkg() { command -v "$1" &>/dev/null || PKGS+=("${2:-$1}"); }
PKGS=()
need_pkg curl; need_pkg rsync; need_pkg jq; need_pkg lsd; need_pkg btop; need_pkg nvim neovim; need_pkg zsh; need_pkg ddate
if ((${#PKGS[@]})); then
  info "Installing: ${PKGS[*]}"
  sudo apt update -qq && sudo apt install -y ${PKGS[*]} >/dev/null
  ok "Packages installed"
else
  ok "All required packages already present"
fi

#############################
# 3. Default shell          #
#############################
if [[ $SHELL != $(command -v zsh) ]]; then
  info "Setting default shell to zsh"
  chsh -s "$(command -v zsh)" "$USER"
  ok "Default shell switched"
fi

#############################
# 4. Oh‑My‑Zsh              #
#############################
ensure_ohmyzsh() {
  command -v git &>/dev/null || { info "Installing git"; sudo apt install -y git >/dev/null; }
  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    info "Installing Oh‑My‑Zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null
    ok "Oh‑My‑Zsh installed"
  else
    git -C "$HOME/.oh-my-zsh" pull --quiet --ff-only && ok "Oh‑My‑Zsh updated"
  fi
}
ensure_ohmyzsh

#############################
# 5. Dotfiles repo          #
#############################
GITHUB_DOTFILES="${1:-${GITHUB_DOTFILES:-}}"
if [[ -n $GITHUB_DOTFILES ]]; then
  info "Syncing dotfiles from $GITHUB_DOTFILES"
  TMPDIR=$(mktemp -d)
  RE_PATH=$(echo "$GITHUB_DOTFILES" | sed -E 's#(git@github.com:|https://github.com/)([^/.]+/[^/.]+).*#\2#')
  for branch in main master; do
    TAR_URL="https://github.com/${RE_PATH}/archive/refs/heads/${branch}.tar.gz"
    if curl -fsSL "$TAR_URL" -o "$TMPDIR/repo.tar.gz"; then break; fi
  done || fail "Cannot download repo archive"
  tar -xzf "$TMPDIR/repo.tar.gz" -C "$TMPDIR"
  SRC=$(find "$TMPDIR" -maxdepth 1 -type d -name '*-*' | head -n1)
  rsync -a --update --quiet --exclude ".git" "$SRC/" "$HOME/"
  ok "Dotfiles copied"
else
  warn "No GITHUB_DOTFILES provided – skipping dotfiles sync"
fi

#############################
# 6. Oh‑My‑Zsh plugins       #
#############################
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_plugin() { [[ -d $2 ]] || git clone --quiet --depth 1 "$1" "$2"; }
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_plugin https://github.com/zsh-users/zsh-autosuggestions.git        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_plugin https://github.com/zsh-users/zsh-completions.git            "$ZSH_CUSTOM/plugins/zsh-completions"
clone_plugin https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git "$ZSH_CUSTOM/plugins/autoupdate"
ok "Zsh plugins ensured"

#############################
# 7. Finish                 #
#############################
ok "Setup complete. Open a new terminal session to start using your environment."
