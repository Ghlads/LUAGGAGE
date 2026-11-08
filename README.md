# LUAGGAGE 🧳

> Lua + luggage : ma config Neovim qui voyage avec moi.

Ma config Neovim en Lua, pensée pour être portable : un `git clone` et on retrouve son environnement sur n'importe quelle machine.

## Prérequis

- [Neovim](https://neovim.io/) >= 0.10
- `git`
- Un compilateur C (`gcc` ou `clang`), utile pour Treesitter
- [ripgrep](https://github.com/BurntSushi/ripgrep) et `fd` (recommandés pour la recherche)
- Une [Nerd Font](https://www.nerdfonts.com/) dans le terminal (pour les icônes)

## Installation

Sauvegarde ton ancienne config si besoin :

```bash
mv ~/.config/nvim ~/.config/nvim.bak
```

Clone le dépôt :

```bash
git clone https://github.com/Ghlads/luaggage ~/.config/nvim
```

Lance Neovim, les plugins s'installent au premier démarrage :

```bash
nvim
```

## Structure

```
~/.config/nvim
├── init.lua            # Point d'entrée
└── lua/
    ├── config/         # Options, keymaps, autocommands
    └── plugins/        # Configuration des plugins
```

## Plugins

<!-- Liste ici les plugins utilisés et pourquoi tu les as choisis -->



## Mise à jour

```bash
cd ~/.config/nvim && git pull
```

## Licence

MIT
