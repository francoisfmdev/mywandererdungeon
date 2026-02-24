-- data/spells.lua - Sorts (baguettes/consommables), precision via hitBonus/critBonus
return {
  fireball = {
    statMag = "intelligence",
    damageMin = 2,
    damageMax = 12,
    damageType = "fire",
    radius = 1,
    range = 8,
    targetType = "projectile",
    hitBonus = 2,
    critBonus = 1,
  },
  heal = {
    statMag = "wisdom",
    damageMin = 2,
    damageMax = 12,
    damageType = "heal",
    targetType = "buff",
  },
  frighten = {
    statMag = "intelligence",
    damageMin = 0,
    damageMax = 2,
    damageType = "dark",
    range = 6,
    targetType = "projectile",
    applyEffect = "fear",
  },
}
