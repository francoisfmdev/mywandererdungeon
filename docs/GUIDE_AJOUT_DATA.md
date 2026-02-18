# Guide d'ajout de données au jeu

Ce document liste **tous les endroits** à mettre à jour quand vous ajoutez du nouveau contenu data-driven.

---

## 1. MONSTRES (`data/entities/monsters.lua`)

### Obligatoire
| Fichier | Rôle |
|---------|------|
| `data/entities/monsters.lua` | Définition : hp, stats, weapon, resistances, loot, nameKey, descriptionKey |

### Liens à mettre à jour
| Cible | Emplacement |
|-------|-------------|
| **Arme du monstre** | `weapon` = id présent dans `data/weapons.lua` |
| **Donjon (spawn)** | `data/dungeons/<id>.lua` → `monsters` : `{ id = "monster_id", weight = N }` |
| **Sprite** | `data/dungeons/<id>.lua` → `entitySprites` : `monster_id = "assets/dungeons/<donjon>/entities/<monster_id>.png"` ou fallback `assets/entities/<monster_id>.png` |
| **i18n** | `data/locale/fr.lua` et `en.lua` → `entity.<monster_id>` (nom) et `entity.<monster_id>_desc` (description) |
| **Boss** | Si boss : `bossId` dans config donjon, `isBoss = true` dans la def |
| **Loot au drop** | `loot` dans la def monstre → chaque `id` doit exister (consumables ou base_equipment) |

---

## 2. ARMES / ÉQUIPEMENT

### Équipement joueur (armes, armures, etc.)
| Fichier | Rôle |
|---------|------|
| `data/items/base_equipment.lua` | Base : slot, allowedSlots, damageMin/Max, statUsed, range, bonuses, ammoType/ammoId si besoin |

### Armes monstres (WeaponRegistry)
| Fichier | Rôle |
|---------|------|
| `data/weapons.lua` | Types d'armes (sword, dagger, bow...) pour monstres ET cohérence avec base_equipment |

### Liens à mettre à jour
| Cible | Emplacement |
|-------|-------------|
| **Loot donjon** | `data/dungeons/<id>.lua` → `loot.weapons.types` : `{ id = "item_id", weight = N }` |
| **Loot monstres** | `monsters.lua` → `loot` : `{ id = "item_id", chance = 0.x }` |
| **Affixes** | `data/affixes.lua` → `allowedSlots` doit inclure le slot de l'item |
| **i18n** | `data/locale/*/item.equipment.<item_id>` |
| **Munitions** | Si arc/arbalète/gun : `ammoType`, `ammoId` + consumable ammo correspondant |

---

## 3. CONSOMMABLES (`data/consumables.lua`)

### Types : potion, scroll, wand, card, ammo, quest
| Champ | Utilisation |
|-------|-------------|
| `id` | Clé unique |
| `nameKey` | Ex: `"item.potion_hp"` pour i18n |
| `type` | potion, scroll, wand, card, **ammo**, quest |
| `effect` | heal_hp, heal_mp, identify, cure_effect, etc. |
| `amount` | Pour potions |
| `spellId` | Pour baguettes (doit exister dans `data/spells.lua`) |
| `chargesMax` | Pour baguettes |
| `ammoFor` | Pour munitions (arrow, bolt, bullet) |

### Liens à mettre à jour
| Cible | Emplacement |
|-------|-------------|
| **i18n** | `item.<id>` dans locale |
| **Loot donjon** | `loot.consumables.types` : `{ id = "consumable_id", weight = N }` |
| **Loot monstres** | `loot` dans monsters.lua |
| **ConsumableEffects** | Si nouveau type d'effet → `core/consumables/consumable_effects.lua` |
| **Loot generator** | Ammo : `item.count` généré ; wand : `item.charges` |

---

## 4. AFFIXES (`data/affixes.lua` + `data/cursed_affixes.lua`)

| Champ | Utilisation |
|-------|-------------|
| `id` | Clé |
| `nameKey` | Ex: `"affix.of_strength"` |
| `bonuses` | { stat = value, ac = value, … } |
| `allowedSlots` | Slots compatibles ou nil = tous |
| `weight` | Tirage aléatoire |

### Liens
| Cible | Emplacement |
|-------|-------------|
| **i18n** | `affix.<id>` et `affix_cursed.<id>` pour maudits |

---

## 5. SORTS (`data/spells.lua`)

| Champ | Utilisation |
|-------|-------------|
| `id` | Clé |
| `nameKey` | i18n |
| `targetType` | projectile, buff |
| `range`, `radius` | Portée / zone |
| `damageMin`, `damageMax`, `damageType` | Dégâts |
| `cost` | Coût en MP |

### Liens
| Cible | Emplacement |
|-------|-------------|
| **i18n** | Clés pour nom/description du sort |
| **Baguettes** | `spellId` dans consumables |

---

## 6. PIÈGES (`data/traps/traps.lua`)

Format : tableau d'entrées avec `id`, `trigger`, `oneShot`, `effect`.
Effets possibles : `damageMin/Max/damageType`, `applyEffect` (doit exister dans `data/effects/effects.lua`).

### Liens
| Cible | Emplacement |
|-------|-------------|
| **Donjon** | `traps.types` : `{ id = "trap_id", weight = N }` |
| **Effects** | `applyEffect` doit exister dans effects.lua |

---

## 7. EFFETS (`data/effects/effects.lua`)

Définir tout effet référencé par pièges, sorts ou potions (`applyEffect`, `cureEffect`, etc.).

---

## 8. DONJONS (`data/dungeons/<id>.lua`)

| Section | Contenu |
|---------|---------|
| `sprites` | floor, wall, exit |
| `entitySprites` | player, `<monster_id>` pour chaque monstre du donjon |
| `monsters` | `{ id, weight }` – ids dans monsters.lua |
| `traps.types` | `{ id, weight }` – ids dans traps.lua |
| `loot.weapons.types` | `{ id, weight }` – ids dans base_equipment.lua |
| `loot.consumables.types` | `{ id, weight }` – ids dans consumables.lua |
| `bossId` | Si winCondition = "boss" |
| `winObjectId` | Si winCondition = "object" |

---

## 9. i18n (`data/locale/fr.lua` et `en.lua`)

| Section | Format | Exemple |
|---------|--------|---------|
| `item.equipment.<id>` | Équipement | `iron_sword = "Epée de fer"` |
| `item.<id>` | Consommables | `arrow = "Flèche"`, `potion_hp = "Potion de soin"` |
| `entity.<id>` | Monstres | `skeleton = "Squelette"` |
| `entity.<id>_desc` | Description monstres | `skeleton_desc = "..."` |
| `affix.<id>` | Affixes | `of_strength = "de Force robuste"` |
| `affix_cursed.<id>` | Affixes maudits | `cursed_weakness = "de Faiblesse"` |
| `log.*` | Messages de combat / événements | `log.attack.no_ammo`, etc. |

---

## 10. ASSETS (sprites)

| Type | Emplacement | Fallback |
|------|-------------|----------|
| Entité donjon | `assets/dungeons/<donjon>/entities/<id>.png` | - |
| Entité générique | - | `assets/entities/<monster_id>.png` |
| Tuiles | `assets/dungeons/<donjon>/floor.png`, `wall.png`, `exit.png` | Couleur |

---

## Checklist rapide par type de contenu

### Nouveau monstre
- [ ] `data/entities/monsters.lua`
- [ ] `data/dungeons/<id>.lua` : monsters, entitySprites
- [ ] `data/locale/*` : entity.\<id\>, entity.\<id\>_desc
- [ ] Asset sprite
- [ ] Loot : ids d'items valides

### Nouvel équipement (arme/armure)
- [ ] `data/items/base_equipment.lua`
- [ ] `data/weapons.lua` (si arme utilisée par monstres)
- [ ] `data/dungeons/<id>.lua` : loot.weapons.types
- [ ] `data/locale/*` : item.equipment.\<id\>
- [ ] `data/affixes.lua` : allowedSlots si affixes spécifiques

### Nouveau consommable
- [ ] `data/consumables.lua`
- [ ] `data/dungeons/<id>.lua` : loot.consumables.types
- [ ] `data/locale/*` : item.\<id\>
- [ ] Si wand : spellId dans spells.lua
- [ ] Si ammo : type "ammo", ammoFor

### Nouveau piège
- [ ] `data/traps/traps.lua`
- [ ] `data/dungeons/<id>.lua` : traps.types
- [ ] `data/effects/effects.lua` si applyEffect nouveau

### Nouveau donjon
- [ ] `data/dungeons/<id>.lua` (config complète)
- [ ] Tous les ids référencés existent (monsters, traps, loot, effects)
- [ ] `data/hub/world.lua` : entrée sur la carte du monde (si applicable)
