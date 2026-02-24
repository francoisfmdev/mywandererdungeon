# Guide : IA et attaques des monstres

Les monstres **n'ont pas d'équipement**. Leurs comportements et attaques sont entièrement définis par configuration dans `data/entities/monsters.lua` et `data/ai/behaviors.lua`.

---

## 1. Comportements IA (behaviors)

Chaque monstre possède un **état** qui change selon la situation :
- **`idle`** : ne détecte pas le joueur (peut errer ou patrouiller selon `idleBehavior`)
- **`alert`** : vient de détecter le joueur
- **`hunting`** : poursuit le joueur (en approche)
- **`attacking`** : à portée, attaque
- **`fleeing`** : fuit (peur ou PV bas)

Les **attaques** sont liées à ces behaviors. Un monstre peut avoir **0, 1 ou plusieurs attaques** par behavior.

---

## 2. Configuration d'un monstre (`data/entities/monsters.lua`)

### Structure de base

```lua
monster_id = {
  id = "monster_id",
  nameKey = "entity.monster_id",
  descriptionKey = "entity.monster_id_desc",
  aiProfile = "aggressive",      -- profil IA (voir section 3)
  detectionRadius = 5,            -- distance de détection (cases)
  hp = 10,
  resistances = { ... },
  loot = { ... },

  -- ATTAQUES PAR BEHAVIOR (obligatoire pour les monstres qui attaquent)
  attacksByBehavior = {
    attacking = { ... },   -- attaques en mêlée (quand à portée)
    hunting = { ... },     -- attaques à distance en approche (optionnel)
    fleeing = { ... },    -- souvent vide ; attaque de repli possible
  },
}
```

### Format d'une attaque

```lua
{
  hitChance = 75,           -- % de toucher (1-100)
  damageMin = 2,
  damageMax = 8,
  damageType = "slashing",  -- slashing, piercing, blunt
  weight = 1,               -- pour tirage pondéré si plusieurs attaques
  applyEffect = "poison",   -- optionnel : effet à appliquer au toucher
  applyEffectChance = 0.3,  -- optionnel : 30% de chance d'appliquer
}
```

### Exemples

**Un monstre avec une seule attaque :**
```lua
attacksByBehavior = {
  attacking = {
    { hitChance = 80, damageMin = 1, damageMax = 6, damageType = "piercing", weight = 1 },
  },
  fleeing = {},
},
```

**Un monstre avec plusieurs attaques (tirage pondéré) :**
```lua
attacksByBehavior = {
  attacking = {
    { hitChance = 50, damageMin = 6, damageMax = 14, damageType = "slashing", weight = 1 },
    { hitChance = 85, damageMin = 2, damageMax = 5, damageType = "slashing", weight = 2 },
  },
  fleeing = {},
},
```
→ 1/3 chance : attaque puissante 50% précision ; 2/3 chance : attaque faible 85% précision.

**Aucune attaque en fuite :**
```lua
fleeing = {},
```

**Attaque avec effet (empoisonnement) :**
```lua
{ hitChance = 70, damageMin = 2, damageMax = 5, damageType = "piercing",
  applyEffect = "poison", applyEffectChance = 0.25, weight = 1 },
```

---

## 3. Profils IA (`data/ai/behaviors.lua`)

Chaque monstre utilise un **profil** via `aiProfile = "nom"`. Les paramètres du monstre (`detectionRadius`, etc.) écrasent ceux du profil.

### Profils disponibles

| Profil     | Détection | Comportement                          |
|------------|-----------|---------------------------------------|
| aggressive | 4 cases   | Charge, attaque en mêlée              |
| coward     | 2 cases   | Peureux, fuit si PV < 40 %            |
| ranged     | 6 cases   | Garde la distance (idealRange 4)      |
| guardian   | 2 cases   | Ne bouge pas, attaque si adjacent     |
| patrol     | 4 cases   | Patrouille autour du point de spawn   |
| stalker    | 8 cases   | Poursuit activement sur grande portée |

### Paramètres modifiables (dans le monstre ou le profil)

| Paramètre        | Rôle                                                |
|------------------|-----------------------------------------------------|
| `detectionRadius`| Distance de détection du joueur                     |
| `attackRange`    | Portée d'attaque (1 = mêlée, 5 = distance)          |
| `chasePlayer`    | `true` = poursuit le joueur                         |
| `fleeOnFear`     | Fuir si effet peur                                  |
| `fleeOnLowHp`    | Fuir si PV bas                                      |
| `hpFleeThreshold`| Seuil PV pour fuir (ex. 0.4 = 40 %)                 |
| `waitChance`     | Chance de passer son tour même à portée             |
| `keepDistance`   | Garde la distance (pour archers)                    |
| `idealRange`     | Distance idéale si keepDistance                      |
| `idleBehavior`   | `"wander"` = errer | `"patrol"` = zone spawn | `"none"` = immobile |
| `patrolRadius`   | Rayon autour du spawn si patrol (ex. 3)             |
| `wanderChance`   | Chance 0–1 de bouger quand idle (ex. 0.5)          |

### Exemple : surcharge pour un monstre

```lua
cultist = {
  aiProfile = "aggressive",
  detectionRadius = 5,   -- surcharge : détecte plus loin que le profil
  ...
},
```

---

## 4. Flux de décision de l'IA

1. **Fuir** si peur ou PV bas (selon config)
2. **Idle** si joueur hors de `detectionRadius` : selon `idleBehavior`, errer (`wander`), patrouiller (`patrol`) ou rester immobile
3. **Attaquer** si joueur à portée (`dist <= attackRange`) et attaques pour ce behavior
4. **Reculer** si `keepDistance` et trop proche
5. **Approcher** le joueur si `chasePlayer`

Quand le monstre attaque :
- En mêlée : behavior = `attacking`
- À distance (avec `keepDistance`) : behavior = `hunting` si à bonne distance
- Si pas d’attaque pour ce behavior : fallback sur `attacking`

---

## 5. Ajouter un nouveau monstre

1. **`data/entities/monsters.lua`** : définir le monstre avec `attacksByBehavior`
2. **`data/locale/en.lua`** et **`fr.lua`** : ajouter `entity.monster_id` et `entity.monster_id_desc`
3. **`data/dungeons/<donjon>.lua`** : ajouter dans `monsters` et `entitySprites`
4. **`assets/entities/monster_id.png`** : sprite 32×32 px

---

## 6. Types de dégâts et résistances

Les `damageType` disponibles : `slashing`, `piercing`, `blunt`.

Chaque monstre (et le joueur) a des **résistances** en % dans son `resistances`. Les dégâts sont réduits ou augmentés selon ces valeurs.

---

## 7. Effets (applyEffect)

Les effets possibles sont définis dans `data/effects/effects.lua` : `poison`, `fear`, `burn`, `slow`, etc.

Pour qu’un monstre applique un effet au toucher :
```lua
{ ..., applyEffect = "poison", applyEffectChance = 0.3, ... }
```

L’effet doit exister dans `data/effects/effects.lua`.
