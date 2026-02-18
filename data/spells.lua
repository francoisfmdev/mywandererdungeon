-- data/spells.lua - Sorts, damageType elementaire : fire|ice|lightning|poison|light|dark
-- targetType: "projectile" (direction, zone), "melee" (corps a corps), "buff" (cible = soi)
return {
  fireball = {
    statMag = "intelligence",
    damageMin = 2,
    damageMax = 12,
    damageType = "fire",
    mpCost = 5,
    radius = 1,
    range = 8,
    targetType = "projectile",
  },
  heal = {
    statMag = "wisdom",
    damageMin = 2,
    damageMax = 12,
    damageType = "heal",
    mpCost = 3,
    targetType = "buff",
  },
}
