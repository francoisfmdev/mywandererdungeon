# Appliquer un effet (ex. peur) à une arme ou un sort

## Sorts (`data/spells.lua`)

Ajoute la propriété **`applyEffect`** au sort :

```lua
frighten = {
  statMag = "intelligence",
  damageMin = 0,
  damageMax = 2,
  damageType = "dark",
  mpCost = 4,
  range = 6,
  targetType = "projectile",
  applyEffect = "fear",   -- applique l'effet "fear" à chaque cible touchée
},
```

- L'effet est appliqué **à chaque coup réussi** (cible unique ou zone).
- L’effet doit exister dans `data/effects/effects.lua`.

---

## Armes (`data/items/base_equipment.lua`)

Ajoute **`applyEffect`** et optionnellement **`applyEffectChance`** à l’arme :

```lua
-- Exemple : épée terrifiante
terrifying_sword = {
  id = "terrifying_sword",
  slot = "weapon_main",
  allowedSlots = { "weapon_main", "weapon_off" },
  damageMin = 2,
  damageMax = 8,
  damageType = "slashing",
  statUsed = "strength",
  range = 1,
  applyEffect = "fear",
  applyEffectChance = 0.25,   -- 25 % de chance par coup (optionnel, défaut 100 %)
  bonuses = {},
},
```

- **`applyEffect`** : id de l’effet à appliquer.
- **`applyEffectChance`** : probabilité 0–1 (ex. 0.25 = 25 %). Si absent, l’effet est appliqué à chaque coup.
- L'effet est appliqué **à chaque coup réussi**.

---

## Armes monstres (`data/weapons.lua`)

Même principe pour les monstres :

```lua
terrifying_claw = {
  statUsed = "strength",
  damageMin = 1,
  damageMax = 6,
  damageType = "slashing",
  range = 1,
  applyEffect = "fear",
  applyEffectChance = 0.3,
},
```

Puis dans `data/entities/monsters.lua` :

```lua
ghost = {
  ...
  weapon = "terrifying_claw",
  ...
},
```

---

## Rappel : piège (backup)

Le piège `fear_trap` existe dans `data/traps/traps.lua`.  
Pour l’utiliser dans un donjon, ajoute-le dans `traps.types` du donjon :

```lua
{ id = "fear_trap", weight = 3 },
```
