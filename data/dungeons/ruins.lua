-- data/dungeons/ruins.lua - Donjon 1 : Les Ruines
return {
  id = "ruins",

  map = {
    width = 80,
    height = 80,
  },

  -- Sprites associes a ce donjon (assets relatifs au projet)
  sprites = {
    floor = "assets/dungeons/ruins/floor.png",
    wall = "assets/dungeons/ruins/wall.png",
  },
  entitySprites = {
    player = "assets/dungeons/ruins/entities/player.png",
    skeleton = "assets/dungeons/ruins/entities/skeleton.png",
    rat = "assets/dungeons/ruins/entities/rat.png",
    cultist = "assets/dungeons/ruins/entities/cultist.png",
  },

  generation = {
    monsterDensityDivisor = 8,
    maxMonstersPerRoom = 3,
    spawnChanceEvery5Turns = 0.08,
    spawnMinDistanceFromPlayer = 12,
    minRooms = 14,
    maxRooms = 22,
    minRoomSize = 5,
    maxRoomSize = 12,
    smallRoomMax = 6,
    mediumRoomMax = 10,
    smallRoomWeight = 1,
    mediumRoomWeight = 3,
    irregularityChance = 0.12,
    classicRoomRatio = 0.6,
    maxEventsPerFloor = 8,
    branchCount = 2,
    branchMaxGap = 3,
    corridorBendThreshold = 6,
    deadEndCount = 3,
    deadEndChance = 0.12,
    deadEndMaxLen = 2,
    pillarChance = 0.4,
    pillarMaxPerRoom = 2,
    alcoveChance = 0.35,
    alcoveMaxDepth = 2,
  },

  monsters = {
    { id = "skeleton", weight = 10 },
    { id = "rat", weight = 20 },
    { id = "cultist", weight = 5 },
  },

  events = {
    { id = "trap_spike", weight = 10 },
    { id = "treasure_room", weight = 5 },
  },

  traps = {
    density = 0.02,
    types = {
      { id = "spike_trap", weight = 10 },
      { id = "poison_trap", weight = 5 },
      { id = "paralysis_trap", weight = 3 },
      { id = "distraction_trap", weight = 2 },
      { id = "silence_trap", weight = 2 },
      { id = "exhaustion_trap", weight = 2 },
    },
  },

  loot = {
    itemLevelMin = 1,
    itemLevelMax = 3,
    weapons = {
      density = 0.007,
      types = {
        { id = "iron_sword", weight = 3 },
        { id = "dagger", weight = 8 },
        { id = "iron_spear", weight = 2 },
        { id = "mace", weight = 4 },
        { id = "wooden_shield", weight = 5 },
        { id = "leather_armor", weight = 4 },
      },
    },
    consumables = {
      density = 0.012,
      types = {
        { id = "potion_minor_hp", weight = 10 },
        { id = "potion_hp", weight = 5 },
        { id = "potion_mp", weight = 5 },
        { id = "wand_fireball", weight = 2 },
        { id = "wand_heal", weight = 2 },
        { id = "card_teleport", weight = 1 },
        { id = "card_purify", weight = 1 },
        { id = "scroll_identify", weight = 2 },
        { id = "antidote", weight = 3 },
        { id = "coffee", weight = 2 },
        { id = "vitamine", weight = 2 },
        { id = "pastille_voix", weight = 2 },
      },
    },
    gold = {
      density = 0.03,
      amountMin = 2,
      amountMax = 10,
    },
  },
}
