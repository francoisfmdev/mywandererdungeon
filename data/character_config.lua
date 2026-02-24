-- data/character_config.lua - Progression item-centric (PV fixes par niveau, pas de MP/magie)
return {
  max_level = 100,
  stat_points_per_level = 1,
  stat_modifier_divisor = 5,

  stats = {
    "strength", "dexterity", "constitution",
    "intelligence", "wisdom", "charisma",
  },
  stats_initial = 3,

  -- PV fixes par niveau : baseHP + level * hpPerLevel (constitution n'affecte plus les PV max)
  baseHP = 25,
  hpPerLevel = 5,

  -- Regen PV (style Shiren) - constitution + config donjon
  hpRegenPerCon = 3,
}
