-- data/affixes.lua - Definitions des affixes (prefixes/suffixes)
return {
  -- Stats
  of_strength = {
    id = "of_strength",
    nameKey = "affix.of_strength",
    bonuses = { stats = { strength = 2 } },
    weight = 6,
  },
  of_dexterity = {
    id = "of_dexterity",
    nameKey = "affix.of_dexterity",
    bonuses = { stats = { dexterity = 2 } },
    weight = 6,
  },
  of_constitution = {
    id = "of_constitution",
    nameKey = "affix.of_constitution",
    bonuses = { stats = { constitution = 2 } },
    weight = 6,
  },
  of_intelligence = {
    id = "of_intelligence",
    nameKey = "affix.of_intelligence",
    bonuses = { stats = { intelligence = 2 } },
    weight = 5,
  },
  of_wisdom = {
    id = "of_wisdom",
    nameKey = "affix.of_wisdom",
    bonuses = { stats = { wisdom = 2 } },
    weight = 5,
  },
  -- Armure & Combat
  sturdy = {
    id = "sturdy",
    nameKey = "affix.sturdy",
    bonuses = { ac = 2 },
    weight = 4,
  },
  reinforced = {
    id = "reinforced",
    nameKey = "affix.reinforced",
    bonuses = { ac = 3 },
    weight = 3,
  },
  vicious = {
    id = "vicious",
    nameKey = "affix.vicious",
    bonuses = { attackBonus = 2 },
    allowedSlots = { "weapon_main", "weapon_off" },
    weight = 3,
  },
  -- Resistances
  of_fire_resistance = {
    id = "of_fire_resistance",
    nameKey = "affix.of_fire_resistance",
    bonuses = { resistances = { fire = 15 } },
    weight = 5,
  },
  of_ice_resistance = {
    id = "of_ice_resistance",
    nameKey = "affix.of_ice_resistance",
    bonuses = { resistances = { ice = 15 } },
    weight = 5,
  },
  of_poison_resistance = {
    id = "of_poison_resistance",
    nameKey = "affix.of_poison_resistance",
    bonuses = { resistances = { poison = 15 } },
    weight = 4,
  },
  of_lightning_resistance = {
    id = "of_lightning_resistance",
    nameKey = "affix.of_lightning_resistance",
    bonuses = { resistances = { lightning = 15 } },
    weight = 4,
  },
  -- Elementaire (armes)
  flaming = {
    id = "flaming",
    nameKey = "affix.flaming",
    bonuses = { elementalDamage = { fire = 2 } },
    allowedSlots = { "weapon_main", "weapon_off" },
    weight = 4,
  },
  frozen = {
    id = "frozen",
    nameKey = "affix.frozen",
    bonuses = { elementalDamage = { ice = 2 } },
    allowedSlots = { "weapon_main", "weapon_off" },
    weight = 4,
  },
  venomous = {
    id = "venomous",
    nameKey = "affix.venomous",
    bonuses = { elementalDamage = { poison = 2 } },
    allowedSlots = { "weapon_main", "weapon_off" },
    weight = 3,
  },
  -- Specifiques
  of_vitality = {
    id = "of_vitality",
    nameKey = "affix.of_vitality",
    bonuses = { bonusMaxHp = 5 },
    weight = 4,
  },
  of_mana = {
    id = "of_mana",
    nameKey = "affix.of_mana",
    bonuses = { bonusMaxMp = 3 },
    weight = 3,
  },
}
