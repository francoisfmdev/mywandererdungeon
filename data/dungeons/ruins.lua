-- data/dungeons/ruins.lua - Config donjon Ruines (3 etages, boss)
-- Sprites: floor, wall, exit uniquement (pas d'autotiling)
return {
  id = "ruins",
  nameKey = "hub.world.ruins",
  totalFloors = 3,
  winCondition = "boss",
  bossId = "skeleton_lord",

  map = {
    width = 56,
    height = 56,
  },

  -- Pieces predessinees (tableaux F/W) + couloirs proceduraux (style Binding of Isaac)
  roomTemplatesPath = "data.dungeons.rooms.ruins_rooms",
  roomTemplates = nil, -- charge depuis roomTemplatesPath si nil

  generation = {
    gridCols = 4,
    gridRows = 4,
    numRooms = 8,
    minRoomSize = 5,
    maxRoomSize = 10,
    minRooms = 4,
    maxRooms = 16,
    smallRoomMax = 6,
    mediumRoomMax = 10,
    largeRoomMax = 14,
    smallRoomWeight = 3,
    mediumRoomWeight = 2,
    largeRoomWeight = 0.5,
    corridorBendThreshold = 1,
    corridorBendChance = 0.3,
    corridorMode = "mst",
    branchCount = 0,
    branchChance = 0,
    branchMaxGap = 0,
    deadEndChance = 0,
    deadEndMaxLen = 0,
    pillarChance = 0,
    pillarMaxPerRoom = 0,
    alcoveChance = 0,
    alcoveMaxPerRoom = 0,
    alcoveMaxDepth = 0,
    irregularityChance = 0,
    classicRoomRatio = 1.0,
    monsterDensityDivisor = 8,
    maxMonstersPerRoom = 3,
    hpRegenFactor = 1.0,
    hpRegenInterval = 3,
  },

  -- Chars etendus pour rooms : TL/TR/BL/BR = coins, P = pilier, D/R/K/J = decors (lettres fixes, sprites par donjon)
  roomTileChars = {
    TL = { type = "wall", sprite = "assets/dungeons/ruins/wall_corner_tl.png" },
    TR = { type = "wall", sprite = "assets/dungeons/ruins/wall_corner_tr.png" },
    BL = { type = "wall", sprite = "assets/dungeons/ruins/wall_corner_bl.png" },
    BR = { type = "wall", sprite = "assets/dungeons/ruins/wall_corner_br.png" },
    P = { type = "wall", sprite = "assets/dungeons/ruins/wall_pillar.png" },
    D = { type = "floor", sprite = "assets/dungeons/ruins/decors_d.png" },
    R = { type = "floor", sprite = "assets/dungeons/ruins/decors_r.png" },
    K = { type = "floor", sprite = "assets/dungeons/ruins/decors_k.png" },
    J = { type = "floor", sprite = "assets/dungeons/ruins/decors_j.png" },
  },

  -- Couleur boite journal (hex) : fond derriere les logs pour lisibilite. Ex: "#1a1a2e", alpha optionnel "#1a1a2e88"
  logBoxColor = "#0a0a1288",

  sprites = {
    floor = {
      base = "assets/dungeons/ruins/floor.png",
      variant = "assets/dungeons/ruins/floor_variant.png",
    },
    wall = {
      top = "assets/dungeons/ruins/wall_top.png",
      bottom = "assets/dungeons/ruins/wall_top.png",
      left = "assets/dungeons/ruins/wall_left.png",
      right = "assets/dungeons/ruins/wall_left.png",
      topVariant = "assets/dungeons/ruins/wall_top_varitant.png",
      leftVariant = "assets/dungeons/ruins/wall_left_variant.png",
      cornerTL = "assets/dungeons/ruins/wall_corner_tl.png",
      cornerTR = "assets/dungeons/ruins/wall_corner_tr.png",
      cornerBL = "assets/dungeons/ruins/wall_corner_bl.png",
      cornerBR = "assets/dungeons/ruins/wall_corner_br.png",
      pillar = "assets/dungeons/ruins/wall_pillar.png",  -- intersections (*), a la place des angles
      default = "assets/dungeons/ruins/wall_top.png",
    },
    exit = "assets/dungeons/ruins/exit.png",
    void = "assets/dungeons/ruins/void.png",
  },

  -- entitySprites : paths = plusieurs fichiers | path + frames = sprite sheet decoupe
  -- entitySpriteScale : 1.0 = sprites pleine taille, 0.9 = reduits pour marge
  entitySpriteScale = 1.0,
  -- Tous les monstres : format paths (image1.png, image1_2.png) comme le rat
  entitySprites = {
    player = { paths = { "assets/generals/hero.png", "assets/generals/hero_2.png" } },
    rat = { paths = { "assets/entities/rat.png", "assets/entities/rat_2.png" } },
    bat = { paths = { "assets/entities/bat.png", "assets/entities/bat_2.png" } },
    gobelin = { paths = { "assets/entities/gobelin.png", "assets/entities/gobelin_2.png" } },
    skeleton = { paths = { "assets/entities/skeleton.png", "assets/entities/skeleton_2.png" } },
    cultist = { paths = { "assets/entities/orc.png", "assets/entities/orc_2.png" } },
    skeleton_lord = { paths = { "assets/entities/skeleton_lord.png", "assets/entities/skeleton_lord_2.png" } },
  },

  monsters = {
    { id = "rat", weight = 4 },
    { id = "bat", weight = 4 },
    { id = "gobelin", weight = 1 },
    { id = "skeleton", weight = 2 },
    { id = "cultist", weight = 1 },
  },

  -- Premier donjon : pieges faibles uniquement (pas de poison) pour apprendre les mecaniques
  traps = {
    types = { { id = "weak_spike", weight = 1 } },
    density = 0.02,
  },

  loot = {
    weapons = {
      types = {
        { id = "dagger", weight = 2 },
        { id = "iron_mace", weight = 1 },
      },
      density = 0.003,
    },
    armor = {
      types = {
        { id = "leather_armor", weight = 2 },
        { id = "chainmail", weight = 1 },
      },
      density = 0.002,
    },
    consumables = {
      types = {},
      density = 0.004,
    },
    gold = {
      density = 0.012,
      amountMin = 1,
      amountMax = 6,
    },
  },
}
