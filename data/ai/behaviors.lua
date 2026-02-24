-- data/ai/behaviors.lua - Profils IA monstres (data-driven)
--
-- Les monstres n'ont PAS d'equipement. Leurs attaques sont definies par behavior
-- dans attacksByBehavior (monsters.lua): attacking, hunting, fleeing.
-- Chaque behavior peut avoir 0, 1 ou plusieurs attaques. fleeing = souvent vide.
--
-- Chaque monstre reference un profil via aiProfile = "nom" ou definit ai = { ... } inline.
-- Les champs inline surchargent ceux du profil.
--
-- Champs disponibles:
--   detectionRadius   : distance de detection du joueur (cases)
--   attackRange       : portee d'attaque (1=melee, >1=distance, doit matcher l'arme du monstre)
--   fleeOnFear        : true = fuir si effet peur
--   fleeOnLowHp       : true = fuir si PV sous le seuil
--   hpFleeThreshold   : 0-1, ex 0.3 = fuir a 30% PV
--   chasePlayer       : true = poursuivre, false = rester sur place
--   waitChance        : 0-1, chance de passer son tour meme en portee (monstres hesitants)
--   keepDistance      : true = garder distance (archers), false = aller au contact
--   idealRange        : distance ideale a maintenir si keepDistance (ex: 4 pour archer)
--
return {
  -- Agressif : court vers le joueur, attaque en melee
  aggressive = {
    detectionRadius = 4,
    attackRange = 1,
    fleeOnFear = true,
    fleeOnLowHp = false,
    chasePlayer = true,
    waitChance = 0,
    idleBehavior = "none",
  },
  -- Peureux : courte vision, fuit facilement, erre en idle
  coward = {
    detectionRadius = 2,
    attackRange = 1,
    fleeOnFear = true,
    fleeOnLowHp = true,
    hpFleeThreshold = 0.4,
    chasePlayer = true,
    waitChance = 0.1,
    idleBehavior = "wander",
    wanderChance = 0.5,
  },
  -- Patrouille : reste dans une zone autour du spawn
  patrol = {
    detectionRadius = 4,
    attackRange = 1,
    fleeOnFear = true,
    fleeOnLowHp = false,
    chasePlayer = true,
    waitChance = 0,
    idleBehavior = "patrol",
    patrolRadius = 3,
    wanderChance = 0.4,
  },
  -- A distance : garde ses distances, attaque a portee
  ranged = {
    detectionRadius = 6,
    attackRange = 5,
    fleeOnFear = true,
    fleeOnLowHp = false,
    chasePlayer = true,
    waitChance = 0,
    keepDistance = true,
    idealRange = 4,
  },
  -- Gardien : ne bouge pas, attaque si adjacent
  guardian = {
    detectionRadius = 2,
    attackRange = 1,
    fleeOnFear = true,
    fleeOnLowHp = false,
    chasePlayer = false,
    waitChance = 0,
  },
  -- Assaillant : portee large, poursuit energiquement
  stalker = {
    detectionRadius = 8,
    attackRange = 1,
    fleeOnFear = true,
    fleeOnLowHp = false,
    chasePlayer = true,
    waitChance = 0,
  },
}
