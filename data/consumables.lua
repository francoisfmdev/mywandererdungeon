-- data/consumables.lua - Potions, baguettes (charges), cartes (style PMD graines)
return {
  -- Potions
  potion_hp = {
    id = "potion_hp",
    nameKey = "item.potion_hp",
    type = "potion",
    effect = "heal_hp",
    amount = 15,
  },
  potion_mp = {
    id = "potion_mp",
    nameKey = "item.potion_mp",
    type = "potion",
    effect = "heal_mp",
    amount = 8,
  },
  potion_minor_hp = {
    id = "potion_minor_hp",
    nameKey = "item.potion_minor_hp",
    type = "potion",
    effect = "heal_hp",
    amount = 6,
  },
  scroll_identify = {
    id = "scroll_identify",
    nameKey = "item.scroll_identify",
    type = "scroll",
    effect = "identify",
  },

  -- Antidotes / soins d'effets
  antidote = {
    id = "antidote",
    nameKey = "item.antidote",
    type = "potion",
    effect = "cure_effect",
    cureEffect = "poison",
  },
  coffee = {
    id = "coffee",
    nameKey = "item.coffee",
    type = "potion",
    effect = "cure_effect",
    cureEffect = "distracted",
  },
  vitamine = {
    id = "vitamine",
    nameKey = "item.vitamine",
    type = "potion",
    effect = "cure_effect",
    cureEffect = "exhausted",
  },
  pastille_voix = {
    id = "pastille_voix",
    nameKey = "item.pastille_voix",
    type = "potion",
    effect = "cure_effect",
    cureEffect = "mutisme",
  },

  -- Baguettes : charges au lieu de MP
  wand_fireball = {
    id = "wand_fireball",
    nameKey = "item.wand_fireball",
    type = "wand",
    spellId = "fireball",
    chargesMax = 3,
  },
  wand_heal = {
    id = "wand_heal",
    nameKey = "item.wand_heal",
    type = "wand",
    spellId = "heal",
    chargesMax = 2,
  },

  -- Cartes (role des graines PMD)
  card_purify = {
    id = "card_purify",
    nameKey = "item.card_purify",
    type = "card",
    effect = "purify",
  },
  card_teleport = {
    id = "card_teleport",
    nameKey = "item.card_teleport",
    type = "card",
    effect = "teleport",
    canTargetMonster = true,
    canTargetSelf = true,
  },
}
