#!/usr/bin/env bash
# valerie.e.warner@gmail.com
# ubuntu-bootstrap.sh
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# ── Colour helpers ─────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD="$(tput bold)"; RESET="$(tput sgr0)"
  BLUE="$(tput setaf 4)"; GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"; RED="$(tput setaf 1)"
else
  BOLD=""; RESET=""; BLUE=""; GREEN=""; YELLOW=""; RED=""
fi
info(){ echo -e "${BLUE}${BOLD}▶${RESET} $*"; }
ok(){   echo -e "${GREEN}${BOLD}✔${RESET} $*"; }
warn(){ echo -e "${YELLOW}${BOLD}!${RESET} $*"; }
fail(){ echo -e "${RED}${BOLD}✖${RESET} $*"; exit 1; }

TMPDIR=""
cleanup(){ [[ -n $TMPDIR && -d $TMPDIR ]] && rm -rf "$TMPDIR"; [[ -f "$HOME/ubuntu-bootstrap.sh" ]] && rm -f "$HOME/ubuntu-bootstrap.sh"; }
trap cleanup EXIT

# ── 1. Privilege check ─────────────────────────────────────────────
[[ $(id -u) -ne 0 ]] || fail "Do not run as root. Use sudo when prompted."

# ── 2. Package handling ────────────────────────────────────────────
if [[ -t 0 ]]; then
  read -rp "${BOLD}Update APT and install required packages? [y/N] ${RESET}" confirm
  [[ ${confirm,,} == y* ]] || fail "Aborted by user."
else
  info "Non-interactive shell detected – proceeding with package install"
fi

source /etc/os-release || true
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
PKGS=()
need(){ command -v "$1" &>/dev/null || PKGS+=("$2"); }
need git git; need curl curl; need wget wget; need rsync rsync; need tree tree; need ncdu ncdu; need jq jq
need lynx lynx; need btop btop; need nvim neovim; need zsh zsh; need ddate ddate
need showmount nfs-common; need locate locate; need mpstat sysstat; need iotop iotop; need iftop iftop

# lsd handling
if ! command -v lsd &>/dev/null; then
  if [[ $CODENAME == jammy ]]; then
    info "Installing lsd .deb (22.04)"
    ver=$(curl -fsSL https://api.github.com/repos/lsd-rs/lsd/releases/latest | jq -r '.tag_name')
    deb="lsd_${ver#v}_amd64.deb"
    curl -fsSL -o /tmp/$deb "https://github.com/lsd-rs/lsd/releases/download/${ver}/$deb"
    sudo -E env NEEDRESTART_MODE=a apt-get update -qq
    sudo -E env NEEDRESTART_MODE=a apt-get install -y /tmp/$deb >/dev/null
    ok "lsd .deb installed"
  else
    PKGS+=(lsd)
  fi
fi

# Deduplicate list
mapfile -t PKGS < <(printf '%s\n' "${PKGS[@]}" | sort -u)
if ((${#PKGS[@]})); then
  info "Installing APT packages: ${PKGS[*]}"
  sudo -E env NEEDRESTART_MODE=a apt-get update -qq
  sudo -E env NEEDRESTART_MODE=a apt-get install -y -qq --no-install-recommends \
       -o Dpkg::Options::="--force-confdef" \
       -o Dpkg::Options::="--force-confold" \
       ${PKGS[*]} >/dev/null
  ok "APT packages installed"
else
  ok "All requested APT packages already present"
fi

# ── 3. Default shell ───────────────────────────────────────────────
if [[ $SHELL != $(command -v zsh) ]]; then
  info "Setting default shell to zsh"
  sudo -E chsh -s "$(command -v zsh)" "$USER"
  ok "Default shell switched"
fi

# ── 4. Oh-My-Zsh ───────────────────────────────────────────────────
ensure_omz(){
  command -v git &>/dev/null || { info "Installing git"; sudo apt-get install -y git >/dev/null; }
  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    info "Installing Oh-My-Zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null
    ok "Oh-My-Zsh installed"
  else
    git -C "$HOME/.oh-my-zsh" pull --quiet --ff-only && ok "Oh-My-Zsh updated"
  fi
  # Secure permissions via compaudit (run inside zsh so $ZSH_VERSION is set)
  zsh -ic 'autoload -Uz compaudit && compaudit | xargs -r chmod g-w,o-w' || true
}
ensure_omz

# ── 5. Dot-files sync (repo wins; no --update) ─────────────────────
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
  rsync -a --quiet --delete \
        --exclude ".git" --exclude "README*" --exclude "*setup.sh*" --exclude ".ssh" \
        "$SRC/" "$HOME/"
  ok "Dotfiles copied"

  # Re-secure OMZ again in case the repo changed perms
  zsh -ic 'autoload -Uz compaudit && compaudit | xargs -r chmod g-w,o-w' || true
  ok "Oh-My-Zsh permissions set"
else
  warn "No GITHUB_DOTFILES provided – skipping dotfiles sync"
fi

# ── 6. Zsh plugins ────────────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone(){ [[ -d $2 ]] || git clone --quiet --depth 1 "$1" "$2"; }
clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone https://github.com/zsh-users/zsh-autosuggestions.git      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-completions.git          "$ZSH_CUSTOM/plugins/zsh-completions"
clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git "$ZSH_CUSTOM/plugins/autoupdate"
ok "Zsh plugins ensured"

# ── 7. Finish ─────────────────────────────────────────────────────
ok "Setup complete."
source ~/.zshrc
