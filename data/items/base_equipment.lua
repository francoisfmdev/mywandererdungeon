-- data/items/base_equipment.lua - Equipement 100% data-driven
--
-- === ARMES ===
--   id, slot, allowedSlots, twoHanded
--   damageMin, damageMax      : plage degats
--   damageType                : slashing|piercing|blunt|fire|ice|lightning|poison|light|dark
--   statUsed                  : strength|dexterity (pour bonus stat)
--   range                     : 1 = corps a corps, >1 = distance
--   hitBonus, critBonus       : precision (+hit, +crit)
--   ammoType, ammoId          : arc/arbalete/fusil (arrow, bolt, bullet) ou throwing
--   applyEffect               : effet on-hit (id effects.lua) ex: "poison", "fear"
--   applyEffectChance         : 0-1 probabilite applicaton effet (defaut 1)
--   bonuses                   : ac, attackBonus, stats, resistances, etc.
--
-- === ARMURE / BOUCLIER / ACCESSOIRES ===
--   id, slot, allowedSlots
--   bonuses :
--     ac                      : defense (armure)
--     defenseBonus            : bonus defense additionnel
--     attackBonus             : bonus attaque
--     stats                   : { strength = 2, dexterity = 1 }
--     resistances             : { fire = 10, ice = 5 }
--     bonusMaxHp               : +PV max
--
return {
  -- ========== ARMES MELEE ==========
  dagger = {
    id = "dagger",
    slot = "weapon_main",
    allowedSlots = { "weapon_main", "weapon_off" },
    twoHanded = false,
    damageMin = 1,
    damageMax = 4,
    damageType = "piercing",
    statUsed = "dexterity",
    range = 1,
    hitBonus = 3,
    critBonus = 2,
    bonuses = {},
  },
  iron_sword = {
    id = "iron_sword",
    slot = "weapon_main",
    allowedSlots = { "weapon_main", "weapon_off" },
    twoHanded = false,
    damageMin = 1,
    damageMax = 8,
    damageType = "slashing",
    statUsed = "strength",
    range = 1,
    hitBonus = 0,
    critBonus = 0,
    bonuses = { ac = 0 },
  },
  iron_spear = {
    id = "iron_spear",
    slot = "weapon_main",
    allowedSlots = { "weapon_main" },
    twoHanded = false,
    damageMin = 1,
    damageMax = 6,
    damageType = "piercing",
    statUsed = "strength",
    range = 2,
    hitBonus = 0,
    critBonus = 0,
    bonuses = {},
  },
  mace = {
    id = "mace",
    slot = "weapon_main",
    allowedSlots = { "weapon_main" },
    twoHanded = false,
    damageMin = 1,
    damageMax = 6,
    damageType = "blunt",
    statUsed = "strength",
    range = 1,
    hitBonus = 0,
    critBonus = 0,
    bonuses = {},
  },
  iron_mace = {
    id = "iron_mace",
    slot = "weapon_main",
    allowedSlots = { "weapon_main" },
    twoHanded = false,
    damageMin = 1,
    damageMax = 10,
    damageType = "blunt",
    statUsed = "strength",
    range = 1,
    baseHitChance = 50,
    critBonus = 0,
    applyEffect = "paralysed",
    applyEffectChance = 0.3,
    bonuses = {},
  },
  greatsword = {
    id = "greatsword",
    slot = "weapon_main",
    allowedSlots = { "weapon_main" },
    twoHanded = true,
    damageMin = 2,
    damageMax = 12,
    damageType = "slashing",
    statUsed = "strength",
    range = 1,
    hitBonus = 0,
    critBonus = 0,
    bonuses = {},
  },
  -- Exemple arme elementaire : epee de feu
  flame_sword = {
    id = "flame_sword",
    slot = "weapon_main",
    allowedSlots = { "weapon_main", "weapon_off" },
    twoHanded = false,
    damageMin = 2,
    damageMax = 8,
    damageType = "fire",
    statUsed = "strength",
    range = 1,
    hitBonus = 0,
    critBonus = 1,
    applyEffect = "burn",
    applyEffectChance = 0.25,
    bonuses = {},
  },
  -- Exemple arme poison
  venom_dagger = {
    id = "venom_dagger",
    slot = "weapon_main",
    allowedSlots = { "weapon_main", "weapon_off" },
    twoHanded = false,
    damageMin = 1,
    damageMax = 4,
    damageType = "piercing",
    statUsed = "dexterity",
    range = 1,
    hitBonus = 3,
    critBonus = 2,
    applyEffect = "poison",
    applyEffectChance = 0.3,
    bonuses = {},
  },

  -- ========== ARMES A DISTANCE ==========
  short_bow = {
    id = "short_bow",
    slot = "weapon_main",
    allowedSlots = { "weapon_main" },
    twoHanded = true,
    damageMin = 1,
    damageMax = 6,
    damageType = "piercing",
    statUsed = "dexterity",
    range = 5,
    hitBonus = 2,
    critBonus = 1,
    ammoType = "arrow",
    ammoId = "arrow",
    bonuses = {},
  },
  crossbow = {
    id = "crossbow",
    slot = "weapon_main",
    allowedSlots = { "weapon_main" },
    twoHanded = true,
    damageMin = 3,
    damageMax = 10,
    damageType = "piercing",
    statUsed = "dexterity",
    range = 6,
    hitBonus = 1,
    critBonus = 0,
    ammoType = "bolt",
    ammoId = "bolt",
    bonuses = {},
  },
  pistol = {
    id = "pistol",
    slot = "weapon_main",
    allowedSlots = { "weapon_main" },
    twoHanded = false,
    damageMin = 4,
    damageMax = 12,
    damageType = "piercing",
    statUsed = "dexterity",
    range = 5,
    hitBonus = 0,
    critBonus = 0,
    ammoType = "bullet",
    ammoId = "bullet",
    bonuses = {},
  },
  throwing_knife = {
    id = "throwing_knife",
    slot = "weapon_main",
    allowedSlots = { "weapon_main", "weapon_off" },
    twoHanded = false,
    damageMin = 1,
    damageMax = 5,
    damageType = "piercing",
    statUsed = "dexterity",
    range = 5,
    hitBonus = 2,
    critBonus = 1,
    ammoType = "throwing",
    bonuses = {},
  },
  javelin = {
    id = "javelin",
    slot = "weapon_main",
    allowedSlots = { "weapon_main" },
    twoHanded = false,
    damageMin = 2,
    damageMax = 8,
    damageType = "piercing",
    statUsed = "strength",
    range = 6,
    hitBonus = 0,
    critBonus = 0,
    ammoType = "throwing",
    bonuses = {},
  },

  -- ========== BOUCLIERS ==========
  wooden_shield = {
    id = "wooden_shield",
    slot = "shield",
    allowedSlots = { "weapon_off" },
    bonuses = { ac = 2 },
  },
  iron_shield = {
    id = "iron_shield",
    slot = "shield",
    allowedSlots = { "weapon_off" },
    bonuses = { ac = 4 },
  },

  -- ========== ARMURE ==========
  leather_armor = {
    id = "leather_armor",
    slot = "armor",
    allowedSlots = { "armor" },
    bonuses = { ac = 3 },
  },
  chainmail = {
    id = "chainmail",
    slot = "armor",
    allowedSlots = { "armor" },
    bonuses = { ac = 6, hitBonus = -5 },
  },
  -- Exemple armure avec resistances
  fire_resistant_armor = {
    id = "fire_resistant_armor",
    slot = "armor",
    allowedSlots = { "armor" },
    bonuses = {
      ac = 4,
      resistances = { fire = 20 },
    },
  },

  -- ========== CASQUES ==========
  leather_boots = {
    id = "leather_boots",
    slot = "boots",
    allowedSlots = { "boots" },
    bonuses = { ac = 1 },
  },
  iron_helmet = {
    id = "iron_helmet",
    slot = "helmet",
    allowedSlots = { "helmet" },
    bonuses = { ac = 2 },
  },
  wool_cape = {
    id = "wool_cape",
    slot = "cape",
    allowedSlots = { "cape" },
    bonuses = { ac = 0 },
  },

  -- ========== ACCESSOIRES ==========
  silver_necklace = {
    id = "silver_necklace",
    slot = "necklace",
    allowedSlots = { "necklace" },
    bonuses = { resistances = { fire = 10 } },
  },
  ring_of_power = {
    id = "ring_of_power",
    slot = "ring",
    allowedSlots = { "ring_1", "ring_2" },
    bonuses = { stats = { strength = 2 } },
  },
  ring_of_protection = {
    id = "ring_of_protection",
    slot = "ring",
    allowedSlots = { "ring_1", "ring_2" },
    bonuses = { ac = 1, resistances = { lightning = 5 } },
  },
  ring_of_vitality = {
    id = "ring_of_vitality",
    slot = "ring",
    allowedSlots = { "ring_1", "ring_2" },
    bonuses = { bonusMaxHp = 5 },
  },
}
