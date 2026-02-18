-- core/dungeon_generator.lua - Generation procedurale donjons data-driven
local M = {}

local Map = require("core.map")

local function weighted_random(items)
  local total = 0
  for _, item in ipairs(items) do
    total = total + (item.weight or 1)
  end
  if total <= 0 then return nil end
  local r = math.random() * total
  for _, item in ipairs(items) do
    r = r - (item.weight or 1)
    if r <= 0 then return item.id end
  end
  return items[#items] and items[#items].id
end

local function bsp_split(rect, gen)
  local min_size = gen.minRoomSize or 4
  if rect.w < min_size * 2 or rect.h < min_size * 2 then
    return { rect }
  end

  local split_h = (rect.w > rect.h) or (rect.w == rect.h and math.random() < 0.5)
  local result = {}

  if split_h then
    local split = math.random(min_size, rect.w - min_size)
    local a = { x = rect.x, y = rect.y, w = split, h = rect.h }
    local b = { x = rect.x + split, y = rect.y, w = rect.w - split, h = rect.h }
    for _, r in ipairs(bsp_split(a, gen)) do table.insert(result, r) end
    for _, r in ipairs(bsp_split(b, gen)) do table.insert(result, r) end
  else
    local split = math.random(min_size, rect.h - min_size)
    local a = { x = rect.x, y = rect.y, w = rect.w, h = split }
    local b = { x = rect.x, y = rect.y + split, w = rect.w, h = rect.h - split }
    for _, r in ipairs(bsp_split(a, gen)) do table.insert(result, r) end
    for _, r in ipairs(bsp_split(b, gen)) do table.insert(result, r) end
  end
  return result
end

local function bsp_partition(width, height, gen)
  local root = { x = 1, y = 1, w = width, h = height }
  local rects = bsp_split(root, gen)
  local max_rooms = math.random(gen.minRooms or 5, gen.maxRooms or 12)
  while #rects > max_rooms do
    table.remove(rects, math.random(#rects))
  end
  return rects
end

local function roll_room_size(min_sz, max_sz, gen)
  local small_max = gen.smallRoomMax or 5
  local medium_max = gen.mediumRoomMax or 8
  local small_weight = gen.smallRoomWeight or 3
  local medium_weight = gen.mediumRoomWeight or 1
  local total = small_weight + medium_weight
  local r = math.random(1, total)
  local lo, hi
  if r <= small_weight then
    lo, hi = min_sz, math.min(small_max, max_sz)
  else
    lo, hi = math.min(small_max + 1, max_sz), math.min(medium_max, max_sz)
  end
  if lo > hi then lo, hi = min_sz, max_sz end
  return math.random(lo, hi)
end

local function create_room(rect, gen)
  local min_sz = gen.minRoomSize or 4
  local max_sz = gen.maxRoomSize or 10
  local rw = roll_room_size(min_sz, math.min(max_sz, rect.w - 2), gen)
  local rh = roll_room_size(min_sz, math.min(max_sz, rect.h - 2), gen)
  local x = rect.x + math.random(1, math.max(1, rect.w - rw - 1))
  local y = rect.y + math.random(1, math.max(1, rect.h - rh - 1))
  return {
    x = x,
    y = y,
    w = rw,
    h = rh,
    cx = x + math.floor(rw / 2),
    cy = y + math.floor(rh / 2),
  }
end

local function carve_room(map, room)
  for dx = 0, room.w - 1 do
    for dy = 0, room.h - 1 do
      local gx, gy = room.x + dx, room.y + dy
      if map:inBounds(gx, gy) then
        map:setTile(gx, gy, "floor")
      end
    end
  end
end

local function shuffle_in_place(t)
  for i = #t, 2, -1 do
    local j = math.random(1, i)
    t[i], t[j] = t[j], t[i]
  end
end

local function carve_segment(map, x1, y1, x2, y2)
  local x, y = x1, y1
  while x ~= x2 do
    if map:inBounds(x, y) then map:setTile(x, y, "floor") end
    x = x + (x2 > x1 and 1 or -1)
  end
  while y ~= y2 do
    if map:inBounds(x, y) then map:setTile(x, y, "floor") end
    y = y + (y2 > y1 and 1 or -1)
  end
end

--- Couloir avec virages pour eviter les longues lignes droites. Insere un point de passage si trop long.
local function carve_corridor(map, x1, y1, x2, y2, gen)
  local bend_threshold = (gen and gen.corridorBendThreshold) or 8
  local dist = math.abs(x2 - x1) + math.abs(y2 - y1)
  if dist <= bend_threshold then
    carve_segment(map, x1, y1, x2, y2)
  else
    local mid_x = math.floor((x1 + x2) / 2)
    local mid_y = math.floor((y1 + y2) / 2)
    local offset = math.random(1, math.min(3, math.floor(dist / 4)))
    if math.random() < 0.5 then
      mid_x = mid_x + (math.random() < 0.5 and offset or -offset)
      mid_x = math.max(2, math.min(map.width - 1, mid_x))
    else
      mid_y = mid_y + (math.random() < 0.5 and offset or -offset)
      mid_y = math.max(2, math.min(map.height - 1, mid_y))
    end
    carve_segment(map, x1, y1, mid_x, mid_y)
    carve_segment(map, mid_x, mid_y, x2, y2)
  end
end

--- Verifie qu'on peut aller de (fx,fy) a (tx,ty) en marchant sur du sol.
local function is_reachable(map, fx, fy, tx, ty)
  if not map:isWalkable(fx, fy) or not map:isWalkable(tx, ty) then
    return false
  end
  local visited = {}
  local key = function(x, y) return x .. "," .. y end
  local queue = { { fx, fy } }
  visited[key(fx, fy)] = true
  local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
  while #queue > 0 do
    local cx, cy = queue[1][1], queue[1][2]
    table.remove(queue, 1)
    if cx == tx and cy == ty then return true end
    for _, d in ipairs(dirs) do
      local nx, ny = cx + d[1], cy + d[2]
      local k = key(nx, ny)
      if map:isWalkable(nx, ny) and not visited[k] then
        visited[k] = true
        table.insert(queue, { nx, ny })
      end
    end
  end
  return false
end

--- Ajoute des couloirs de raccourci entre salles. Limites par branchMaxGap pour eviter les trop longs.
local function add_branch_corridors(map, rooms, gen)
  local count = gen.branchCount or 0
  local chance = gen.branchChance or 0
  local max_gap = gen.branchMaxGap or 5
  if count <= 0 and chance <= 0 then return end
  local n = count > 0 and count or (math.random(1, math.max(1, #rooms - 2)))
  for _ = 1, n do
    if #rooms < 3 then break end
    local a, b = math.random(1, #rooms), math.random(1, #rooms)
    if a > b then a, b = b, a end
    if b - a >= 2 and (b - a) <= max_gap and math.random() < (chance > 0 and chance or 1) then
      carve_corridor(map, rooms[a].cx, rooms[a].cy, rooms[b].cx, rooms[b].cy, gen)
    end
  end
end

local function add_dead_ends(map, rooms, gen)
  local count = gen.deadEndCount or 0
  local chance = gen.deadEndChance or 0.3
  if count <= 0 and chance <= 0 then return end
  local n = count > 0 and count or math.random(2, math.max(2, #rooms * 2))
  local candidates = {}
  for _, room in ipairs(rooms) do
    for dx = -1, 1 do
      for dy = -1, 1 do
        if (dx ~= 0 or dy ~= 0) and map:inBounds(room.cx + dx, room.cy + dy)
          and map:isWalkable(room.cx + dx, room.cy + dy) then
          table.insert(candidates, { room.cx + dx, room.cy + dy, dx, dy })
        end
      end
    end
  end
  for x = 2, map.width - 1 do
    for y = 2, map.height - 1 do
      if map:isWalkable(x, y) then
        local wall_dirs = {}
        for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
          local nx, ny = x + d[1], y + d[2]
          if map:inBounds(nx, ny) and not map:isWalkable(nx, ny) then
            table.insert(wall_dirs, { d[1], d[2] })
          end
        end
        if #wall_dirs > 0 then
          local d = wall_dirs[math.random(1, #wall_dirs)]
          table.insert(candidates, { x, y, d[1], d[2] })
        end
      end
    end
  end
  if #candidates == 0 then return end
  shuffle_in_place(candidates)
  local placed = 0
  for _, c in ipairs(candidates) do
    if placed >= n then break end
    if math.random() <= chance then
      local x, y, dx, dy = c[1], c[2], c[3], c[4]
      local max_len = gen.deadEndMaxLen or 2
      local len = math.random(1, math.max(1, max_len))
      for _ = 1, len do
        x, y = x + dx, y + dy
        if not map:inBounds(x, y) then break end
        map:setTile(x, y, "floor")
        placed = placed + 1
      end
    end
  end
end

--- Piliers : murs d'1 case au milieu de certaines salles pour varier.
local function add_room_pillars(map, rooms, gen)
  local chance = gen.pillarChance or 0.35
  local max_per_room = gen.pillarMaxPerRoom or 2
  if chance <= 0 then return end
  for _, room in ipairs(rooms) do
    if room.w >= 5 and room.h >= 5 and math.random() < chance then
      local interior = {}
      for dx = 2, room.w - 3 do
        for dy = 2, room.h - 3 do
          local gx, gy = room.x + dx, room.y + dy
          if map:isWalkable(gx, gy) then
            local near_center = math.abs(gx - room.cx) <= 1 and math.abs(gy - room.cy) <= 1
            if not near_center then
              table.insert(interior, { gx, gy })
            end
          end
        end
      end
      if #interior > 0 then
        shuffle_in_place(interior)
        local n = math.min(max_per_room, math.random(1, math.max(1, math.floor(#interior / 4))))
        for i = 1, n do
          local pos = interior[i]
          if pos and map:isWalkable(pos[1], pos[2]) then
            map:setTile(pos[1], pos[2], "wall")
          end
        end
      end
    end
  end
end

--- Renfoncements / alcoves : petites niches dans les murs des salles.
local function add_room_alcoves(map, rooms, gen)
  local chance = gen.alcoveChance or 0.3
  local max_deep = gen.alcoveMaxDepth or 2
  if chance <= 0 then return end
  for _, room in ipairs(rooms) do
    if (room.w >= 4 or room.h >= 4) and math.random() < chance then
      local edges = {}
      for dx = 0, room.w - 1 do
        for dy = 0, room.h - 1 do
          local gx, gy = room.x + dx, room.y + dy
          if map:isWalkable(gx, gy) then
            for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
              local nx, ny = gx + d[1], gy + d[2]
              if map:inBounds(nx, ny) and not map:isWalkable(nx, ny) then
                table.insert(edges, { nx, ny, d[1], d[2] })
              end
            end
          end
        end
      end
      if #edges > 0 then
        local pick = edges[math.random(1, #edges)]
        local x, y, dx, dy = pick[1], pick[2], pick[3], pick[4]
        local depth = math.random(1, math.min(max_deep, 2))
        for _ = 1, depth do
          if map:inBounds(x, y) then
            map:setTile(x, y, "floor")
            x, y = x + dx, y + dy
          end
        end
      end
    end
  end
end

--- Applique de l'irregularite a une partie des murs pour varier les formes.
--- Certaines salles restent classiques (rectangulaires), d'autres gagnent des
--- contours plus organiques. Mélange salle classique / salle irrégulière.
local function apply_irregularity(map, gen, rooms)
  local chance = gen.irregularityChance or 0
  if chance <= 0 then return end
  local classic_ratio = gen.classicRoomRatio or 0.5
  local room_classic = {}
  for i = 1, #rooms do
    room_classic[i] = (math.random() > classic_ratio)
  end
  for x = 2, map.width - 1 do
    for y = 2, map.height - 1 do
      if map:getTile(x, y).type == "wall" and math.random() < chance then
        local floor_neighbors = 0
        for dx = -1, 1 do
          for dy = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and map:isWalkable(x + dx, y + dy) then
              floor_neighbors = floor_neighbors + 1
            end
          end
        end
        if floor_neighbors >= 2 then
          local in_classic_room = false
          for i, room in ipairs(rooms) do
            if room_classic[i] then
              local rx1, rx2 = room.x - 1, room.x + room.w
              local ry1, ry2 = room.y - 1, room.y + room.h
              if x >= rx1 and x <= rx2 and y >= ry1 and y <= ry2 then
                in_classic_room = true
                break
              end
            end
          end
          if not in_classic_room then
            map:setTile(x, y, "floor")
          end
        end
      end
    end
  end
end

local function get_floor_positions_in_room(room, map)
  local positions = {}
  for dx = 0, room.w - 1 do
    for dy = 0, room.h - 1 do
      local gx, gy = room.x + dx, room.y + dy
      if not map or map:isWalkable(gx, gy) then
        table.insert(positions, { gx, gy })
      end
    end
  end
  return positions
end

local function place_entities(map, rooms, config, entrance_room_idx)
  local monsters = config.monsters or {}
  if #monsters == 0 then return end

  local gen_cfg = config.generation or {}
  local divisor = gen_cfg.monsterDensityDivisor or 8
  local maxPerRoom = gen_cfg.maxMonstersPerRoom or 3

  for i, room in ipairs(rooms) do
    if i ~= entrance_room_idx then
      local positions = get_floor_positions_in_room(room, map)
      local count = math.random(0, math.min(maxPerRoom, math.max(0, math.floor(#positions / divisor))))
      shuffle_in_place(positions)
      for j = 1, math.min(count, #positions) do
        local pos = positions[j]
        local id = weighted_random(monsters)
        if id then
          map:addEntity(pos[1], pos[2], id)
        end
      end
    end
  end
end

local function place_events(map, rooms, config, entrance_room_idx)
  local events = config.events or {}
  if #events == 0 then return end

  local max_events = (config.generation or {}).maxEventsPerFloor or 5
  local placed = 0

  for i, room in ipairs(rooms) do
    if i ~= entrance_room_idx and placed < max_events then
      local positions = get_floor_positions_in_room(room, map)
      if #positions > 0 and math.random() < 0.5 then
        local pos = positions[math.random(1, #positions)]
        local id = weighted_random(events)
        if id then
          map:addEvent(pos[1], pos[2], id)
          placed = placed + 1
        end
      end
    end
  end
end

local function do_generate(dungeonConfig, depth)
  depth = depth or 1
  local map_cfg = dungeonConfig.map or {}
  local gen_cfg = dungeonConfig.generation or {}
  local width = map_cfg.width or 80
  local height = map_cfg.height or 80

  local map = Map.new(width, height)
  local rects = bsp_partition(width, height, gen_cfg)
  local rooms = {}

  for _, rect in ipairs(rects) do
    local room = create_room(rect, gen_cfg)
    if room.w >= 2 and room.h >= 2 then
      table.insert(rooms, room)
      carve_room(map, room)
    end
  end

  if #rooms < 1 then return nil end

  shuffle_in_place(rooms)
  for i = 1, #rooms - 1 do
    carve_corridor(map, rooms[i].cx, rooms[i].cy, rooms[i + 1].cx, rooms[i + 1].cy, gen_cfg)
  end

  add_branch_corridors(map, rooms, gen_cfg)
  add_dead_ends(map, rooms, gen_cfg)
  add_room_pillars(map, rooms, gen_cfg)
  add_room_alcoves(map, rooms, gen_cfg)

  if gen_cfg.irregularityChance and gen_cfg.irregularityChance > 0 then
    apply_irregularity(map, gen_cfg, rooms)
  end

  local entrance_idx = 1
  local exit_idx = #rooms
  local entrance = { rooms[entrance_idx].cx, rooms[entrance_idx].cy }
  local exit_pos = { rooms[exit_idx].cx, rooms[exit_idx].cy }

  map:setTile(entrance[1], entrance[2], "floor")
  map:setTile(exit_pos[1], exit_pos[2], "floor")

  place_entities(map, rooms, dungeonConfig, entrance_idx)
  place_events(map, rooms, dungeonConfig, entrance_idx)

  return {
    map = map,
    rooms = rooms,
    entrance = { x = entrance[1], y = entrance[2] },
    exit = { x = exit_pos[1], y = exit_pos[2] },
  }
end

--- Genere un donjon parcourable : on peut toujours aller de l'entree a la sortie a pied.
--- Le donjon est a sens unique : en prenant la sortie on descend, on ne remonte jamais.
--- Regeneration jusqu'a obtention d'un donjon finissable (pas de limite).
function M.generate(dungeonConfig, depth)
  while true do
    local result = do_generate(dungeonConfig, depth)
    if result and is_reachable(result.map, result.entrance.x, result.entrance.y, result.exit.x, result.exit.y) then
      return result
    end
  end
end

return M
