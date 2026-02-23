## Tools
- [Cursor](https://cursor.com/)
- [mise](https://mise.jdx.dev/)


## Fonts
- Terminal: [JetBrains Mono Nerd Font](https://www.nerdfonts.com/font-downloads)
- Editor: [MesloLGLDZ Nerd Font](https://www.nerdfonts.com/font-downloads)
- Writing: [Poly](https://fonts.google.com/specimen/Poly)
- Marketing: [Barlow Semi Condensed](https://fonts.google.com/specimen/Barlow+Semi+Condensed)


## Brew
- awscli
- delta (diffs)
- eza (ls)
- zsh
- zsh-fast-syntax-highlighting


## OS
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/)


## Setup

```bash
./install.sh
```


## Linux

Install zsh and set it as default shell:

```bash
sudo apt install zsh
chsh -s $(which zsh)
```

Install tools:

```bash
curl -s https://ohmyposh.dev/install.sh | bash -s          # oh-my-posh
curl https://mise.run | sh                                  # mise
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh  # zoxide
sudo apt install eza                                        # eza (Ubuntu 24.04+)
sudo apt install git-delta                                  # delta
```

Install zsh-fast-syntax-highlighting:

```bash
git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
  ~/.local/share/zsh-fast-syntax-highlighting
```

Nerd Fonts must be installed on your **local machine** (the one you SSH from), not the remote box.


## Ignore a project's upstream `.cursor` folder

```bash
cd ~/code/project
git sparse-checkout init --no-cone
printf '/-\n!/--/.cursor/--\n' > .git/info/sparse-checkout
git checkout .
```
