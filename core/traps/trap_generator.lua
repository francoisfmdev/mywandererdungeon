-- core/traps/trap_generator.lua - Generation procedurale des pieges
local M = {}

local TrapInstance = require("core.traps.trap_instance")
local TrapRegistry = require("core.traps.trap_registry")

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

--- Genere les pieges sur la carte.
--- map, dungeonConfig, depth, entrance, exit utilises.
function M.generate(map, dungeonConfig, depth, entrance, exit)
  if not map or not dungeonConfig then return end
  local trapCfg = dungeonConfig.traps
  if not trapCfg or not trapCfg.types or #trapCfg.types == 0 then return end

  local density = tonumber(trapCfg.density) or 0.05
  depth = depth or 1

  local floorCount = 0
  for x = 1, map.width do
    for y = 1, map.height do
      if map:isWalkable(x, y) then
        floorCount = floorCount + 1
      end
    end
  end

  local trapCount = math.floor(floorCount * density)
  if trapCount < 1 then return end

  local ex, ey = nil, nil
  if entrance and entrance.x and entrance.y then
    ex, ey = entrance.x, entrance.y
  end
  local sx, sy = nil, nil
  if exit and exit.x and exit.y then
    sx, sy = exit.x, exit.y
  end

  local candidates = {}
  for x = 1, map.width do
    for y = 1, map.height do
      if map:isWalkable(x, y) then
        if (ex and ey and x == ex and y == ey) or (sx and sy and x == sx and y == sy) then
        else
          table.insert(candidates, { x, y })
        end
      end
    end
  end

  for i = #candidates, 2, -1 do
    local j = math.random(1, i)
    candidates[i], candidates[j] = candidates[j], candidates[i]
  end

  local placed = 0
  for i = 1, math.min(trapCount, #candidates) do
    local pos = candidates[i]
    local x, y = pos[1], pos[2]
    local tile = map:getTile(x, y)
    if tile and not tile.trap then
      local trapId = weighted_random(trapCfg.types)
      if trapId then
        local def = TrapRegistry.get(trapId)
        if def then
          local levelMin = def.levelMin or 1
          local levelMax = def.levelMax or 100
          if depth >= levelMin and depth <= levelMax then
            local inst = TrapInstance.new(trapId, x, y, def)
            if inst then
              tile.trap = inst
              placed = placed + 1
            end
          end
        end
      end
    end
  end
end

return M
