-- data/dungeons/rooms/ruins_rooms.lua
-- Templates : F=floor, W=wall, TL/TR/BL/BR=coins, P=pilier, D/R/K/J=4 decors (lettres fixes)
return {
  -- Petites pieces (5x5 a 7x7)
  {
    id = "small_1",
    tiles = {
      { "TL","W","W","W","W","TR" },
      { "W","F","F","F","F","W" },
      { "W","F","F","F","F","W" },
      { "W","F","F","F","F","W" },
      { "BL","W","W","W","W","BR" },
    },
    weight = 3,
  },
  {
    id = "small_2",
    tiles = {
      { "TL","W","W","W","W","W","TR" },
      { "W","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","W" },
      { "BL","W","W","W","W","W","BR" },
    },
    weight = 4,
  },
  -- Pieces moyennes (9x9)
  {
    id = "medium_1",
    tiles = {
      { "TL","W","W","W","W","W","W","W","TR" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "BL","W","W","W","W","W","W","W","BR" },
    },
    weight = 2,
  },
  -- Piece avec pilier central (P = sprite pilier via chars)
  {
    id = "medium_pillar",
    tiles = {
      { "TL","W","W","W","W","W","W","W","TR" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","P","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","P","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","W" },
      { "BL","W","W","W","W","W","W","W","BR" },
    },
    chars = { P = { type = "wall", sprite = "assets/dungeons/ruins/wall_pillar.png" } },
    weight = 1,
  },
  -- Grandes pieces (11x11)
  {
    id = "large_1",
    tiles = {
      { "TL","W","W","W","W","W","W","W","W","W","TR" },
      { "W","F","F","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","F","F","W" },
      { "W","F","F","P","F","F","F","P","F","F","W" },
      { "W","F","F","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","F","F","W" },
      { "W","F","F","P","F","F","F","P","F","F","W" },
      { "W","F","F","F","F","F","F","F","F","F","W" },
      { "W","F","F","F","F","F","F","F","F","F","W" },
      { "BL","W","W","W","W","W","W","W","W","W","BR" },
    },
    weight = 1,
  },
}
