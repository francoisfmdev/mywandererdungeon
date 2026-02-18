-- data/weapons.lua - Armes, damageMin/Max, damageType, range
return {
  sword = {
    statUsed = "strength",
    damageMin = 1,
    damageMax = 8,
    damageType = "slashing",
    range = 1,
  },
  dagger = {
    statUsed = "dexterity",
    damageMin = 1,
    damageMax = 4,
    damageType = "piercing",
    range = 1,
  },
  mace = {
    statUsed = "strength",
    damageMin = 1,
    damageMax = 6,
    damageType = "blunt",
    range = 1,
  },
}
