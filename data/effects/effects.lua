-- data/effects/effects.lua - Definitions des effets (data-driven)
return {
  -- Paralysé : 3 tours, ne peut que passer son tour
  paralysed = {
    id = "paralysed",
    duration = 3,
    stacking = "refresh",
    type = "debuff",
    blockMove = true,
    blockAttack = true,
    blockCast = true,
    blockUseItem = true,
  },
  -- Poison : dégâts progressifs, soigné par antidote
  poison = {
    id = "poison",
    duration = 5,
    stacking = "refresh",
    type = "debuff",
    onTurnStart = { damageMin = 1, damageMax = 4, damageType = "poison" },
    modifiers = { speed = -1 },
  },
  -- Déconcentré : double consommation MP, soigné par café
  distracted = {
    id = "distracted",
    duration = 4,
    stacking = "refresh",
    type = "debuff",
    mpCostMultiplier = 2,
  },
  -- Mutisme : 5 tours, pas de sorts mais baguettes OK, soigné par pastille
  mutisme = {
    id = "mutisme",
    duration = 5,
    stacking = "refresh",
    type = "debuff",
    blockCast = true,
  },
  -- Exténué : pas de regen PV/PM, soigné par vitamines
  exhausted = {
    id = "exhausted",
    duration = 5,
    stacking = "refresh",
    type = "debuff",
    blockRegen = true,
  },
  burn = {
    id = "burn",
    duration = 3,
    stacking = "refresh",
    type = "debuff",
    onTurnStart = { damageMin = 1, damageMax = 6, damageType = "fire" },
    modifiers = {},
  },
  slow = {
    id = "slow",
    duration = 4,
    stacking = "refresh",
    type = "debuff",
    modifiers = {
      speed = -2,
    },
  },
  strength_bonus = {
    id = "strength_bonus",
    duration = 3,
    stacking = "refresh",
    type = "buff",
    modifiers = {
      stats = { strength = 2 },
    },
  },
  resistance_bonus = {
    id = "resistance_bonus",
    duration = 5,
    stacking = "ignore",
    type = "buff",
    modifiers = {
      resistances = { physical = 10 },
    },
  },
}
