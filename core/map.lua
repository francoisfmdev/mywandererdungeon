-- core/map.lua - Structure de carte de donjon
local M = {}

function M.new(width, height)
  local self = {}
  self.width = width
  self.height = height
  self.grid = {}

  self.explored = {}
  for x = 1, width do
    self.grid[x] = {}
    self.explored[x] = {}
    for y = 1, height do
      self.grid[x][y] = {
        type = "wall",
        entities = {},
        event = nil,
        trap = nil,
        groundGold = 0,
        groundItems = {},
      }
      self.explored[x][y] = false
    end
  end

  function self:isWalkable(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
      return false
    end
    return self.grid[x][y].type == "floor"
  end

  function self:setTile(x, y, tileType)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
      self.grid[x][y].type = tileType
    end
  end

  function self:addEntity(x, y, id)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
      table.insert(self.grid[x][y].entities, id)
    end
  end

  function self:addEvent(x, y, id)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
      self.grid[x][y].event = id
    end
  end

  function self:addGroundLoot(x, y, gold, items)
    if x < 1 or x > self.width or y < 1 or y > self.height then return end
    local tile = self.grid[x][y]
    if gold and gold > 0 then tile.groundGold = (tile.groundGold or 0) + gold end
    if items then
      tile.groundItems = tile.groundItems or {}
      for _, it in ipairs(items) do table.insert(tile.groundItems, it) end
    end
  end

  function self:getGroundLoot(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then return 0, {} end
    local tile = self.grid[x][y]
    return tile.groundGold or 0, tile.groundItems or {}
  end

  function self:clearGroundLoot(x, y)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
      self.grid[x][y].groundGold = 0
      self.grid[x][y].groundItems = {}
    end
  end

  function self:setGroundGold(x, y, amount)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
      self.grid[x][y].groundGold = amount or 0
    end
  end

  function self:removeGroundItemAt(x, y, index)
    if x < 1 or x > self.width or y < 1 or y > self.height then return nil end
    local tile = self.grid[x][y]
    local items = tile.groundItems
    if not items or index < 1 or index > #items then return nil end
    local item = table.remove(items, index)
    return item
  end

  function self:getTile(x, y)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
      return self.grid[x][y]
    end
    return nil
  end

  function self:inBounds(x, y)
    return x >= 1 and x <= self.width and y >= 1 and y <= self.height
  end

  function self:setExplored(x, y)
    x, y = math.floor(tonumber(x) or 0), math.floor(tonumber(y) or 0)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
      local row = self.explored[x]
      if row then row[y] = true end
    end
  end

  function self:isExplored(x, y)
    x, y = math.floor(tonumber(x) or 0), math.floor(tonumber(y) or 0)
    if x < 1 or x > self.width or y < 1 or y > self.height then
      return false
    end
    local row = self.explored[x]
    return row and row[y] == true
  end

  function self:exploreAround(cx, cy, radius)
    cx = math.floor(tonumber(cx) or 0)
    cy = math.floor(tonumber(cy) or 0)
    local r = math.max(0, tonumber(radius) or 5)
    for dx = -r, r do
      for dy = -r, r do
        if dx * dx + dy * dy <= r * r then
          self:setExplored(cx + dx, cy + dy)
        end
      end
    end
  end

  return self
end

return M
