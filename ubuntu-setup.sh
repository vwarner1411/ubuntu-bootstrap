#!/usr/bin/env bash
# valerie.e.warner@gmail.com
# ubuntu-bootstrap.sh

set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a

# ── logging ───────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  B=$(tput bold); R=$(tput sgr0)
  C=$(tput setaf 4); G=$(tput setaf 2); Y=$(tput setaf 3); E=$(tput setaf 1)
else B= R= C= G= Y= E=; fi
log(){ printf "%b▶%b %s\n" "$C$B" "$R" "$*"; }
ok(){  printf "%b✔%b %s\n" "$G$B" "$R" "$*"; }
warn(){printf "%b!%b %s\n" "$Y$B" "$R" "$*"; }
die(){ printf "%b✖%b %s\n" "$E$B" "$R" "$*"; exit 1; }

[[ $(id -u) -eq 0 ]] && die "Run as your normal user (not root)."
sudo -n true 2>/dev/null || { log "You may be prompted for sudo…"; sudo -v; }

source /etc/os-release || true
CODENAME=${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}

# ── 1) packages ───────────────────────────────────────────────────
PKGS=(git curl wget rsync tree ncdu lynx btop neovim zsh jq
      nfs-common locate sysstat iotop iftop)

# lsd: jammy needs .deb; noble ships it
if ! command -v lsd &>/dev/null; then
  if [[ $CODENAME == jammy ]]; then
    log "Installing lsd from GitHub (22.04)"
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    ver=$(curl -fsSL https://api.github.com/repos/lsd-rs/lsd/releases/latest | jq -r .tag_name)
    deb="lsd_${ver#v}_amd64.deb"
    curl -fsSL -o "$tmp/$deb" "https://github.com/lsd-rs/lsd/releases/download/$ver/$deb"
    sudo apt-get update -qq
    sudo apt-get install -y "$tmp/$deb"
  else
    PKGS+=(lsd)
  fi
fi

missing=(); for p in "${PKGS[@]}"; do dpkg -s "$p" &>/dev/null || missing+=("$p"); done
if ((${#missing[@]})); then
  log "Installing APT packages: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends "${missing[@]}"
else ok "All required packages present"; fi

# ── 2) Oh-My-Zsh first ────────────────────────────────────────────
install_omz() {
  log "Installing / updating Oh-My-Zsh"
  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    env RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null
  else
    git -C "$HOME/.oh-my-zsh" pull --quiet --ff-only || true
  fi
  # compaudit fix (inside zsh so $ZSH_VERSION exists)
  zsh -ic 'autoload -Uz compaudit && compaudit | xargs -r chmod g-w,o-w' || true
  chmod -R go-w "$HOME/.oh-my-zsh" || true
  ok "Oh-My-Zsh ready"
}
install_omz

# ── 3) Dot-files AFTER OMZ (repo mirrors into $HOME; repo wins) ───
sync_dotfiles() {
  local arg="${1:-}" envrepo="${GITHUB_DOTFILES:-}" src=""
  local here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

  # priority: CLI arg → env → current repo → default
  if [[ -n $arg ]]; then
    src="$arg"
  elif [[ -n $envrepo ]]; then
    src="$envrepo"
  elif git -C "$here" rev-parse --show-toplevel &>/dev/null; then
    src="$(git -C "$here" rev-parse --show-toplevel)"
  else
    src="https://github.com/vwarner1411/ubuntu-bootstrap"
  fi

  log "Syncing dot-files from: $src"
  local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN

  if [[ -d $src ]]; then
    # local path (including running from inside the repo)
    rsync -a --delete --exclude '.git' --exclude '.ssh' "$src/" "$HOME/"
  else
    # remote: clone shallow then mirror
    if [[ $src =~ ^(git@|https?://) ]]; then
      git -c advice.detachedHead=false clone --depth 1 --quiet "$src" "$tmp/repo"
    else
      git -c advice.detachedHead=false clone --depth 1 --quiet "https://$src" "$tmp/repo"
    fi
    rsync -a --delete --exclude '.git' --exclude '.ssh' "$tmp/repo/" "$HOME/"
  fi

  # re-secure OMZ in case repo changed perms
  zsh -ic 'autoload -Uz compaudit && compaudit | xargs -r chmod g-w,o-w' || true
  ok "Dot-files mirrored to \$HOME"
}
sync_dotfiles "${1:-}"

# ── 4) zsh plugins ─────────────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone(){ [[ -d $2 ]] || git clone --depth 1 --quiet "$1" "$2"; }
clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone https://github.com/zsh-users/zsh-autosuggestions.git      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-completions.git          "$ZSH_CUSTOM/plugins/zsh-completions"
clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git "$ZSH_CUSTOM/plugins/autoupdate"
ok "Zsh plugins ensured"

# ── 5) make zsh default shell (once) ──────────────────────────────
if [[ $SHELL != "$(command -v zsh)" ]]; then
  log "Changing login shell to zsh"
  sudo chsh -s "$(command -v zsh)" "$USER"
fi

ok "Setup complete. Start zsh with: exec zsh -l"
