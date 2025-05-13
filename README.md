# Ubuntu Bootstrap

Automate your **fresh Ubuntu 22.04 / 24.04** install into a fully‑themed workstation/server in one shot:

* **zsh + Oh My Zsh** with the Dracula Pro prompt
* **Neovim** with Dracula Pro colours
* **lsd** directory listing & **btop** system monitor – both Dracula‑skinned
* **All your dotfiles** (aliases, git config, SSH, etc.) copied straight from this repo

---

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/vwarner1411/ubuntu-bootstrap/main/ubuntu-setup.sh | \
  GITHUB_DOTFILES=https://github.com/vwarner1411/ubuntu-bootstrap bash
```

*No Git required.* The script downloads the repo as a tarball with **curl** and only installs **git** later if Oh‑My‑Zsh isn’t already on the box.

### Re‑run any time

```bash
./ubuntu-setup.sh   # assumes repo already cloned
#  – or –
GITHUB_DOTFILES=git@github.com:you/your-dotfiles.git ./ubuntu-setup.sh
```

Every run mirrors the repo back onto `$HOME` with `rsync --delete`, so updates are painless.

---

## What the script does

| Category | Packages / tools | Notes |
|----------|------------------|-------|
| Shell & core | `zsh` + **Oh‑My‑Zsh** | Sets default shell, installs/upgrades OMZ, fixes directory perms. |
| Prompt extras | Dracula‑Pro theme, `zsh‑syntax‑highlighting`, `zsh‑autosuggestions`, `zsh‑completions`, `autoupdate` |
| Editors & viewers | `neovim`, `tree`, `ncdu`, `lynx` |
| System utils | `curl`, `wget`, `rsync`, `jq`, `btop`, `ddate`, `git` |
| Directory listing | **`lsd`** (colourful `ls` replacement) | Via **snap** on 22.04, via **apt** on 24.04+ |
| Theming | Dracula theme for btop, LSD colours, Dracula‑Pro for Neovim |
| Dot‑files | Repo tarball is downloaded, then `rsync -a --update` into `$HOME` — *no deletions*; excludes `.ssh`, READMEs, `*setup.sh*`. |
| Permissions | `.ssh` fixed to `0700 / 0600`, OMZ fixed to `0755` |
| Cleanup | Temp dir + any copied `ubuntu-bootstrap.sh` removed |

---

## Contents of this repo

```
ubuntu-bootstrap/
├── ubuntu-bootstrap.sh               # bootstrap script (v13)
├── .zshrc                            # shell config referencing dracula‑pro prompt
├── .oh-my-zsh/
│   └── custom/
│       └── themes/
│           └── dracula-pro.zsh-theme
├── .config/
│   ├── btop/
│   │   └── themes/
│   │       └── dracula.theme         # Dracula palette for btop
│   └── lsd/
│       ├── colors.yaml               # 256‑colour mapping for lsd
│       └── config.yaml               # lsd layout/icons settings
├── .local/
│   └── share/nvim/site/pack/themes/start/dracula_pro/
│       ├── colors/                   # dracula_pro.vim + palette variants
│       ├── autoload/
│       │   ├── dracula_pro.vim
│       │   └── …
│       ├── after/
│       │   ├── plugin/dracula_pro.vim
│       │   └── syntax/*.vim          # language‑specific tweaks
│       └── README.md (upstream)
└── README.md                         # you’re reading it
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

---

## License

MIT © 2025 [vwarner1411](https://github.com/vwarner1411) – Dracula theme © their respective authors.
