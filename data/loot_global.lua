-- data/loot_global.lua - Objets generaux (cartes type graines PMD)
-- Ces objets peuvent apparaitre sur N'IMPORTE QUEL etage de N'IMPORTE QUEL donjon.
-- Ils sont rares ( faible densite ) et independants de la config loot du donjon.

return {
  -- Densite : nombre moyen d'objets par case au sol (ex. 0.002 = ~2 objets pour 1000 cases)
  density = 0.002,

  -- Types : { id, weight } - ids dans consumables.lua
  -- weight relatif pour le tirage pondere
  types = {
    { id = "card_teleport", weight = 1 },
    { id = "card_purify", weight = 1 },
    { id = "coffee", weight = 1 },
    { id = "vitamine", weight = 1 },
    { id = "sirop", weight = 1 },
  },
}
