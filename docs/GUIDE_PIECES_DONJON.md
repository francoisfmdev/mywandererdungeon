# Guide : Pièces prédessinées pour le donjon (style Binding of Isaac)

## Principe

- **Tu dessines** les pièces en tableaux (F = sol, W = mur)
- **Le générateur** place les pièces sur une grille et les relie par des couloirs procéduraux

## Format d'une pièce

Édite `data/dungeons/rooms/ruins_rooms.lua` :

**Lignes en tableaux** (recommandé, permet plusieurs caractères) :
```lua
{
  id = "ma_piece",
  tiles = {
    { "W","W","W","W","W","W","W" },
    { "W","F","F","F","F","F","W" },
    { "W","F","F","P","F","F","W" },   -- P = pilier (via chars)
    { "W","F","F","F","F","F","W" },
    { "W","W","W","W","W","W","W" },
  },
  chars = { P = { type = "wall", sprite = "assets/dungeons/ruins/wall_pillar.png" } },
  weight = 3,
},
```

**Lignes en chaînes** (legacy, toujours supporté) :
```lua
tiles = { "WWWWWWW", "WFFFFFW", ... },
```

- **F**/**f** = floor (sol)
- **W**/**w** = wall (mur)
- **TL/TR/BL/BR** = coins (config donjon)
- **P** = pilier (config donjon)
- **D, R, K, J** = 4 decors (lettres fixes, sprites par donjon : decors_d.png, decors_r.png, etc.)
- **Chars étendus** : `template.chars` ou `ruins.roomTileChars` → caractère → `{ type, sprite? }`
- Toutes les lignes doivent avoir la même longueur (rectangle)

## Exemples de formes

**Petite (5x5) :**
```
WWWWW
WFFFW
WFFFW
WFFFW
WWWWW
```

**Avec pilier :**
```
WWWWWWWWW
WFFFFFFFW
WFFFWFFFW
WFFFFFFFW
WFFFFFFFW
WWWWWWWWW
```

**L-shaped (à venir si support) :** pour l'instant, garde des rectangles.

## Génération (style Binding of Isaac)

1. **Floorplan** : grille de cellules, BFS depuis le centre, 50% chance d'ajouter un voisin (pas de boucles)
2. **Placement** : chaque cellule reçoit une pièce tirée au hasard selon les poids
3. **Couloirs** : connexion automatique entre pièces adjacentes (droits ou en L)

## Configuration (ruins.lua)

```lua
roomTemplatesPath = "data.dungeons.rooms.ruins_rooms",
generation = {
  gridCols = 4,
  gridRows = 4,
  numRooms = 8,    -- nombre de pièces à placer
  ...
},
```

## Tailles recommandées

- **Petites** : 5x5 à 7x7
- **Moyennes** : 9x9
- **Grandes** : 11x11 max (limité par la taille des cellules de la grille)

La cellule fait 14x14 (carte 56x56, grille 4x4). Centre bien ta pièce dans cet espace.
