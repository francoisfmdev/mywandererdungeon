-- core/dungeon_generator.lua - Generation donjons style Binding of Isaac
--
-- Pieces predessinees en tableaux + couloirs proceduraux.
-- 1. Floorplan : grille de cellules, quelles ont des pieces (BFS)
-- 2. Placement : pose les templates de pieces sur la carte
-- 3. Couloirs : relie les pieces adjacentes (droits ou en L)
--
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
    if r <= 0 then return item end
  end
  return items[#items]
end

--- Genere le floorplan : grille de cellules, lesquelles ont une piece (style Isaac).
--- BFS depuis le centre, 50% chance d'ajouter un voisin. Pas de boucles.
local function generate_floorplan(cols, rows, num_rooms)
  num_rooms = math.min(num_rooms, cols * rows)
  local grid = {}
  for c = 1, cols do
    grid[c] = {}
    for r = 1, rows do
      grid[c][r] = false
    end
  end
  local start_col = math.floor(cols / 2) + 1
  local start_row = math.floor(rows / 2) + 1
  grid[start_col][start_row] = true
  local queue = { { start_col, start_row } }
  local placed = 1
  local end_rooms = {}
  local reseed_count = 0

  while placed < num_rooms do
    if #queue == 0 then
      reseed_count = reseed_count + 1
      if reseed_count > 10 then break end
      table.insert(queue, { start_col, start_row })
    end
    local cell = table.remove(queue, 1)
    local col, row = cell[1], cell[2]
    local dirs = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }
    for _, d in ipairs(dirs) do
      local nc, nr = col + d[1], row + d[2]
      if nc >= 1 and nc <= cols and nr >= 1 and nr <= rows and not grid[nc][nr] and placed < num_rooms then
        if math.random() >= 0.5 then
          local filled_neighbors = 0
          for _, d2 in ipairs(dirs) do
            local nnc, nnr = nc + d2[1], nr + d2[2]
            if nnc >= 1 and nnc <= cols and nnr >= 1 and nnr <= rows and grid[nnc][nnr] then
              filled_neighbors = filled_neighbors + 1
            end
          end
          if filled_neighbors <= 1 then
            grid[nc][nr] = true
            placed = placed + 1
            table.insert(queue, { nc, nr })
          end
        end
      end
    end
  end

  for c = 1, cols do
    for r = 1, rows do
      if grid[c][r] then
        local filled = 0
        for _, d in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
          local nc, nr = c + d[1], r + d[2]
          if nc >= 1 and nc <= cols and nr >= 1 and nr <= rows and grid[nc][nr] then
            filled = filled + 1
          end
        end
        if filled <= 1 then
          table.insert(end_rooms, { c, r })
        end
      end
    end
  end

  return grid, end_rooms, { start_col, start_row }
end

--- Place un template de piece sur la carte.
--- tiles : lignes = strings "WFFFFW" OU tableaux { "W","F","F","F","W" }
--- chars (template ou config) : caractere -> { type, sprite? } pour decors (ex: P=pilier, D=deco)
local DEFAULT_CHARS = {
  F = { type = "floor" }, f = { type = "floor" },
  W = { type = "wall" },  w = { type = "wall" },
}
local function place_room_template(map, template, gx, gy, config)
  local tiles = template.tiles
  local row1 = tiles[1]
  local tw = type(row1) == "table" and #row1 or #(row1 or "")
  local th = #tiles
  local chars = {}
  for k, v in pairs(DEFAULT_CHARS) do chars[k] = v end
  local cfg_chars = config and config.roomTileChars
  if cfg_chars then for k, v in pairs(cfg_chars) do chars[k] = v end end
  if template.chars then for k, v in pairs(template.chars) do chars[k] = v end end

  for dy = 0, th - 1 do
    local row = tiles[dy + 1]
    local len = type(row) == "table" and #row or #(row or "")
    for dx = 0, len - 1 do
      local ch
      if type(row) == "table" then
        ch = row[dx + 1]
        if type(ch) ~= "string" then ch = ch and tostring(ch) or " " end
        ch = (ch and #ch > 0) and ch:gsub("^%s+", ""):gsub("%s+$", "") or " "
      else
        ch = row:sub(dx + 1, dx + 1)
      end
      local tx, ty = gx + dx, gy + dy
      if map:inBounds(tx, ty) and ch and ch ~= " " then
        local def = chars[ch]
        if def then
          if def.sprite then
            map:setTileData(tx, ty, { type = def.type, sprite = def.sprite })
          else
            map:setTile(tx, ty, def.type)
          end
        end
      end
    end
  end
  return { x = gx, y = gy, w = tw, h = th, cx = gx + math.floor(tw / 2), cy = gy + math.floor(th / 2) }
end

--- Creuse un couloir droit ou en L, LARGEUR PAIRE (2 cases) pour ne pas casser les sprites.
local CORRIDOR_WIDTH = 2

local function carve_line_h(map, y, x_start, x_end)
  for x = math.min(x_start, x_end), math.max(x_start, x_end) do
    if map:inBounds(x, y) then map:setTile(x, y, "floor") end
    if map:inBounds(x, y + 1) then map:setTile(x, y + 1, "floor") end
  end
end

local function carve_line_v(map, x, y_start, y_end)
  for y = math.min(y_start, y_end), math.max(y_start, y_end) do
    if map:inBounds(x, y) then map:setTile(x, y, "floor") end
    if map:inBounds(x + 1, y) then map:setTile(x + 1, y, "floor") end
  end
end

local function carve_corridor(map, x1, y1, x2, y2, use_l)
  if use_l and math.random() < 0.4 then
    local bend_x = math.floor((x1 + x2) / 2)
    carve_line_h(map, y1, x1, bend_x)
    carve_line_v(map, bend_x, y1, y2)
    carve_line_h(map, y2, bend_x, x2)
  else
    carve_line_h(map, y1, x1, x2)
    carve_line_v(map, x2, y1, y2)
  end
end

--- Vide l'interieur des murs : mur sans voisin sol -> void.
--- Garde angles : ne pas convertir si floor en diagonale (coin interieur L).
local function hollow_interior_walls(map)
  local cardinals = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
  local diagonals = { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
  local changed = true
  while changed do
    changed = false
    for x = 1, map.width do
      for y = 1, map.height do
        local t = map:getTile(x, y)
        if t and t.type == "wall" then
          local floor_cardinal = 0
          for _, d in ipairs(cardinals) do
            if map:inBounds(x + d[1], y + d[2]) and map:isWalkable(x + d[1], y + d[2]) then
              floor_cardinal = floor_cardinal + 1
            end
          end
          local floor_diag = 0
          for _, d in ipairs(diagonals) do
            if map:inBounds(x + d[1], y + d[2]) and map:isWalkable(x + d[1], y + d[2]) then
              floor_diag = floor_diag + 1
            end
          end
          if floor_cardinal == 0 and floor_diag == 0 then
            map:setTile(x, y, "void")
            changed = true
          end
        end
      end
    end
  end
end

--- Remplit les zones void adjacentes au sol par des murs (invariant).
local function close_void_with_walls(map)
  local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
  for x = 1, map.width do
    for y = 1, map.height do
      if map:getTile(x, y).type == "void" then
        for _, d in ipairs(dirs) do
          if map:inBounds(x + d[1], y + d[2]) and map:isWalkable(x + d[1], y + d[2]) then
            map:setTile(x, y, "wall")
            break
          end
        end
      end
    end
  end
end

--- Verifie qu'on peut aller de (fx,fy) a (tx,ty) en marchant sur du sol.
local function is_reachable(map, fx, fy, tx, ty)
  if not map:isWalkable(fx, fy) or not map:isWalkable(tx, ty) then return false end
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

local function shuffle_in_place(t)
  for i = #t, 2, -1 do
    local j = math.random(1, i)
    t[i], t[j] = t[j], t[i]
  end
end

local function get_floor_positions_in_room(room, map)
  local positions = {}
  for dx = 0, (room.w or 1) - 1 do
    for dy = 0, (room.h or 1) - 1 do
      local gx, gy = (room.x or 0) + dx, (room.y or 0) + dy
      if map and map:isWalkable(gx, gy) then
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
        local total = 0
        for _, m in ipairs(monsters) do total = total + (m.weight or 1) end
        if total > 0 then
          local r = math.random() * total
          for _, m in ipairs(monsters) do
            r = r - (m.weight or 1)
            if r <= 0 then
              map:addEntity(pos[1], pos[2], m.id)
              break
            end
          end
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
        local total = 0
        for _, e in ipairs(events) do total = total + (e.weight or 1) end
        if total > 0 then
          local r = math.random() * total
          for _, e in ipairs(events) do
            r = r - (e.weight or 1)
            if r <= 0 then
              map:addEvent(pos[1], pos[2], e.id)
              placed = placed + 1
              break
            end
          end
        end
      end
    end
  end
end

--- Genere un donjon : pieces predessinees + couloirs proceduraux (style Binding of Isaac).
function M.doGenerate(dungeonConfig, depth)
  depth = depth or 1
  local map_cfg = dungeonConfig.map or {}
  local gen_cfg = dungeonConfig.generation or {}
  local width = map_cfg.width or 56
  local height = map_cfg.height or 56

  local room_templates = dungeonConfig.roomTemplates
  if not room_templates and dungeonConfig.roomTemplatesPath then
    room_templates = require(dungeonConfig.roomTemplatesPath)
  end
  if not room_templates or #room_templates == 0 then
    return nil
  end

  local cols = gen_cfg.gridCols or 4
  local rows = gen_cfg.gridRows or 4
  local num_rooms = gen_cfg.numRooms or (5 + math.random(0, 2) + math.floor(depth * 2.6))
  num_rooms = math.max(4, math.min(num_rooms, cols * rows))

  local cell_w = math.floor(width / cols)
  local cell_h = math.floor(height / rows)

  local map = Map.new(width, height)

  -- 1. Floorplan
  local grid, end_rooms, start_cell = generate_floorplan(cols, rows, num_rooms)
  local start_col, start_row = start_cell[1], start_cell[2]

  -- 2. Placement des pieces
  local rooms = {}
  local grid_rooms = {}

  for col = 1, cols do
    grid_rooms[col] = {}
    for row = 1, rows do
      if grid[col][row] then
        local template = weighted_random(room_templates)
        if not template or not template.tiles or #template.tiles == 0 then return nil end
        local row1 = template.tiles[1]
        local tw = type(row1) == "table" and #row1 or #(row1 or "")
        local th = #template.tiles
        local gx = (col - 1) * cell_w + math.floor((cell_w - tw) / 2)
        local gy = (row - 1) * cell_h + math.floor((cell_h - th) / 2)
        gx = math.max(1, math.min(gx, width - tw - 1))
        gy = math.max(1, math.min(gy, height - th - 1))

        local room_data = place_room_template(map, template, gx, gy, dungeonConfig)
        room_data.col, room_data.row = col, row
        table.insert(rooms, room_data)
        grid_rooms[col][row] = room_data
      else
        grid_rooms[col][row] = nil
      end
    end
  end

  if #rooms < 2 then return nil end

  -- 3. Couloirs entre pieces adjacentes
  local dirs = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }
  for col = 1, cols do
    for row = 1, rows do
      local room_a = grid_rooms[col][row]
      if room_a then
        for _, d in ipairs(dirs) do
          local nc, nr = col + d[1], row + d[2]
          if nc >= 1 and nc <= cols and nr >= 1 and nr <= rows then
            local room_b = grid_rooms[nc][nr]
            if room_b then
              carve_corridor(map, room_a.cx, room_a.cy, room_b.cx, room_b.cy, true)
            end
          end
        end
      end
    end
  end

  -- 4. Une seule rangée de mur : au-dela = void (cases noires)
  hollow_interior_walls(map)
  close_void_with_walls(map)

  -- 5. Entrance = piece de depart, Exit = piece la plus eloignee (dernier end_room)
  table.sort(rooms, function(a, b)
    return (a.cy or 0) * 1000 + (a.cx or 0) < (b.cy or 0) * 1000 + (b.cx or 0)
  end)

  local entrance_idx = 1
  local exit_idx = #rooms
  for i, r in ipairs(rooms) do
    if r.col == start_col and r.row == start_row then
      entrance_idx = i
      break
    end
  end
  if #end_rooms > 0 then
    local last = end_rooms[#end_rooms]
    for i, r in ipairs(rooms) do
      if r.col == last[1] and r.row == last[2] then
        exit_idx = i
        break
      end
    end
  end

  local entrance = { rooms[entrance_idx].cx, rooms[entrance_idx].cy }
  local exit_pos = { rooms[exit_idx].cx, rooms[exit_idx].cy }
  map:setTile(entrance[1], entrance[2], "floor")
  map:setTile(exit_pos[1], exit_pos[2], "floor")

  place_entities(map, rooms, dungeonConfig, entrance_idx)
  place_events(map, rooms, dungeonConfig, entrance_idx)

  local result = {
    map = map,
    rooms = rooms,
    entrance = { x = entrance[1], y = entrance[2] },
    exit = { x = exit_pos[1], y = exit_pos[2] },
  }

  if not is_reachable(map, result.entrance.x, result.entrance.y, result.exit.x, result.exit.y) then
    return nil
  end

  return result
end

--- Genere jusqu'a obtenir un donjon parcourable (retry interne).
function M.generate(dungeonConfig, depth)
  for _ = 1, 100 do
    local result = M.doGenerate(dungeonConfig, depth)
    if result then return result end
  end
  return nil
end

return M
