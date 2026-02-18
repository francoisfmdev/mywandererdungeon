# The Wanderer Eternal - Dungeons

Socle roguelike top-down, tour par tour. Lua + Love2D.

## Lancement

```bash
love .
```

(Requiert [Love2D](https://love2d.org/) installé)

## Structure

- `main.lua` - Bootstrap
- `core/` - App, SceneManager, Router, i18n, input, config, log, fs
- `scenes/` - MainMenu, Options, Credits, Hub
- `data/` - UI, bindings, locales (en, fr)
- `platform/` - love.lua (Love2D), dummy_platform.lua (stub)

## Contrôles

- Flèches / W-S : navigation
- Entrée : confirmer
- Échap : retour / quitter

## Langues

Options > sélectionner FR ou EN. Persisté dans config.lua (save directory Love2D).
