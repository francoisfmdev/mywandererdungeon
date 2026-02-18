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
  -- Armes de jet : consomment 1 unite par tir
  throwing_knife = {
    statUsed = "dexterity",
    damageMin = 1,
    damageMax = 5,
    damageType = "piercing",
    range = 5,
    ammoType = "throwing",
  },
  javelin = {
    statUsed = "strength",
    damageMin = 2,
    damageMax = 8,
    damageType = "piercing",
    range = 6,
    ammoType = "throwing",
  },
  -- Arc : necessite fleches
  bow = {
    statUsed = "dexterity",
    damageMin = 1,
    damageMax = 6,
    damageType = "piercing",
    range = 5,
    ammoType = "arrow",
    ammoId = "arrow",
  },
  -- Arbalete : necessite carreaux
  crossbow = {
    statUsed = "dexterity",
    damageMin = 3,
    damageMax = 10,
    damageType = "piercing",
    range = 6,
    ammoType = "bolt",
    ammoId = "bolt",
  },
  -- Arme a feu : necessite munitions
  gun = {
    statUsed = "dexterity",
    damageMin = 4,
    damageMax = 12,
    damageType = "piercing",
    range = 5,
    ammoType = "bullet",
    ammoId = "bullet",
  },
}
