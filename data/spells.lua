-- data/spells.lua - Sorts, damageType elementaire : fire|ice|lightning|poison|light|dark
return {
  fireball = {
    statMag = "intelligence",
    damageMin = 2,
    damageMax = 12,
    damageType = "fire",
    mpCost = 5,
    radius = 1,
  },
  heal = {
    statMag = "wisdom",
    damageMin = 2,
    damageMax = 12,
    damageType = "heal",
    mpCost = 3,
  },
}
