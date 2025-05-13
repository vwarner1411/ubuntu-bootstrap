# Ubuntu 24.04 Bootstrap

Automate your **fresh Ubuntu 22.04 / 24.04** install into a fully‑themed workstation/server in one shot:

* **zsh + Oh My Zsh** with the Dracula Pro prompt
* **Neovim** with Dracula Pro colours
* **lsd** directory listing & **btop** system monitor – both Dracula‑skinned
* **All your dotfiles** (aliases, git config, SSH, etc.) copied straight from this repo

---

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/vwarner1411/ubuntu-2204-bootstrap/main/ubuntu-2204-setup.sh | \
  GITHUB_DOTFILES=https://github.com/vwarner1411/ubuntu-2204-bootstrap bash
```

*No Git required.* The script downloads the repo as a tarball with **curl** and only installs **git** later if Oh‑My‑Zsh isn’t already on the box.

### Re‑run any time

```bash
./ubuntu-2204-setup.sh   # assumes repo already cloned
#  – or –
GITHUB_DOTFILES=git@github.com:you/your-dotfiles.git ./ubuntu-2204-setup.sh
```

Every run mirrors the repo back onto `$HOME` with `rsync --delete`, so updates are painless.

---

## What the script does

1. **Checks packages** – installs only what’s missing (`zsh neovim lsd btop ddate curl rsync jq`).
2. **Switches your login shell** to `zsh`.
3. **Installs Oh My Zsh** (adds `git` on‑demand) and loads the **Dracula‑Pro** theme shipped in the repo.
4. **Downloads this repo** as a tarball and **rsyncs** every file/folder into `$HOME`.
5. **Cleans up everything** – temp directory *and* the installer script self‑delete.

---

## Repo layout (example)

```
.
├── ubuntu-2204-setup.sh          # bootstrap script (self‑destructs)
├── .zshrc                        # shell config (calls dracula‑pro)
├── .oh-my-zsh/
│   └── custom/themes/dracula-pro.zsh-theme
├── .config/
│   ├── nvim/init.vim             # Neovim config (Dracula‑Pro)
│   ├── btop/themes/dracula.theme
│   └── lsd/{config.yaml,colors.yaml}
└── .local/share/nvim/site/pack/themes/start/dracula_pro/…
    # full colour‑scheme so Neovim works offline
```

Add **anything else** you want replicated – `.gitconfig`, `.ssh/config`, `etc/systemd/`, `starship.toml`, language runtimes, etc.  The rsync step mirrors paths exactly.

---

## Customising the bootstrap

| Want to…                           | Edit …                                     |
| ---------------------------------- | ------------------------------------------ |
| Install extra APT packages         | `need()` list inside the script            |
| Keep the script (no self‑delete)   | comment out `rm -- "$0"` at the bottom     |
| Provision via cloud‑init / Ansible | open a PR or issue – contributions welcome |

---

## FAQ

<details>

It’s tested on Ubuntu 22.04 & 24.04. Most derivatives should work if package names match.

</details>


<details>
<summary>Why tarball instead of <code>git clone</code>?</summary>

* **Works without Git** on the target host.
* Faster (\~300 KB vs multi‑MB clone).
* Avoids leaving a `.git` directory in `$HOME`.

</details>

---

## License

MIT © 2025 [vwarner1411](https://github.com/vwarner1411) – Dracula theme © their respective authors.
