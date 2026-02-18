-- data/cursed_affixes.lua - Affixes maudits (negatifs)
return {
  cursed_weakness = {
    id = "cursed_weakness",
    nameKey = "affix.cursed_weakness",
    cursed = true,
    bonuses = { stats = { strength = -2 } },
    weight = 4,
  },
  cursed_clumsiness = {
    id = "cursed_clumsiness",
    nameKey = "affix.cursed_clumsiness",
    cursed = true,
    bonuses = { stats = { dexterity = -2 } },
    weight = 4,
  },
  cursed_frailty = {
    id = "cursed_frailty",
    nameKey = "affix.cursed_frailty",
    cursed = true,
    bonuses = { stats = { constitution = -2 } },
    weight = 4,
  },
  cursed_feeblemind = {
    id = "cursed_feeblemind",
    nameKey = "affix.cursed_feeblemind",
    cursed = true,
    bonuses = { stats = { intelligence = -2 } },
    weight = 3,
  },
  cursed_brittle = {
    id = "cursed_brittle",
    nameKey = "affix.cursed_brittle",
    cursed = true,
    bonuses = { ac = -2 },
    weight = 5,
  },
  cursed_heavy = {
    id = "cursed_heavy",
    nameKey = "affix.cursed_heavy",
    cursed = true,
    bonuses = { ac = -3 },
    weight = 3,
  },
  cursed_sapping = {
    id = "cursed_sapping",
    nameKey = "affix.cursed_sapping",
    cursed = true,
    bonuses = { bonusMaxHp = -5 },
    weight = 4,
  },
  cursed_draining = {
    id = "cursed_draining",
    nameKey = "affix.cursed_draining",
    cursed = true,
    bonuses = { bonusMaxMp = -3 },
    weight = 3,
  },
}
