-- data/character_config.lua - Progression coherente avec combat simplifie (sans competences)
return {
  max_level = 100,
  stat_points_per_level = 1,
  stat_modifier_divisor = 5,

  stats = {
    "strength", "dexterity", "constitution",
    "intelligence", "wisdom", "charisma",
  },
  stats_initial = 3,

  -- MaxHP = 20 + (constitution * 3) + (level * 2)
  baseHP = 20,
  hpPerCon = 3,
  hpPerLevel = 2,

  -- MaxMP = 10 + (intelligence * 1) + floor((level - 1) / 3)
  baseMP = 10,
  mpPerInt = 1,
  mpPerLevelDiv = 3,

  -- Regen par tour (style Shiren) - joueur uniquement
  hpRegenPerCon = 4,   -- floor(constitution / 4) PV par tour
  mpRegenPerInt = 4,   -- floor(intelligence / 4) PM par tour
}
