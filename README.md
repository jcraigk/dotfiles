## Tools
- [Cursor](https://cursor.com/)
- mise


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


## Link relevant dotfiles

```bash
ln -s ~/code/dotfiles/.gitconfig ./.gitconfig
ln -s ~/code/dotfiles/.irbrc ./.irbrc
ln -s ~/code/dotfiles/.zshrc ./.zshrc
```


## Ignore a project's upstream `.cursor` folder

```bash
cd ~/code/project
git sparse-checkout init --no-cone
printf '/-\n!/--/.cursor/--\n' > .git/info/sparse-checkout
git checkout .
```
