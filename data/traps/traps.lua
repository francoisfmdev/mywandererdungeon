-- data/traps/traps.lua - Definitions des pieges (data-driven)
return {
  {
    id = "spike_trap",
    trigger = "step",
    oneShot = true,
    levelMin = 1,
    levelMax = 100,
    effect = {
      damageMin = 1,
      damageMax = 6,
      damageType = "piercing",
    },
  },
  {
    id = "poison_trap",
    trigger = "step",
    oneShot = false,
    levelMin = 1,
    levelMax = 100,
    effect = {
      applyEffect = "poison",
    },
  },
  {
    id = "paralysis_trap",
    trigger = "step",
    oneShot = true,
    levelMin = 1,
    levelMax = 100,
    effect = {
      applyEffect = "paralysed",
    },
  },
  {
    id = "distraction_trap",
    trigger = "step",
    oneShot = false,
    levelMin = 1,
    levelMax = 100,
    effect = {
      applyEffect = "distracted",
    },
  },
  {
    id = "silence_trap",
    trigger = "step",
    oneShot = false,
    levelMin = 1,
    levelMax = 100,
    effect = {
      applyEffect = "mutisme",
    },
  },
  {
    id = "exhaustion_trap",
    trigger = "step",
    oneShot = false,
    levelMin = 1,
    levelMax = 100,
    effect = {
      applyEffect = "exhausted",
    },
  },
}
