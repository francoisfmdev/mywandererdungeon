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
  -- Déconcentré : soigné par café (effet mécanique retiré avec suppression MP)
  distracted = {
    id = "distracted",
    duration = 4,
    stacking = "refresh",
    type = "debuff",
  },
  -- Mutisme : 5 tours, pas de sorts mais baguettes OK, soigné par pastille
  mutisme = {
    id = "mutisme",
    duration = 5,
    stacking = "refresh",
    type = "debuff",
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

  -- Etheree : 1 a 10 tours, degats physiques (tranchant/percant/contondant) = 0, degats magiques x2
  ethereal = {
    id = "ethereal",
    durationMin = 1,
    durationMax = 10,
    stacking = "refresh",
    type = "debuff",
  },

  -- Peur : 1 a 4 tours, n'attaque pas, tente de fuir, sinon passe son tour
  fear = {
    id = "fear",
    durationMin = 1,
    durationMax = 4,
    stacking = "refresh",
    type = "debuff",
    blockAttack = true,
    blockUseItem = true,
    forceFlee = true,
  },
}
