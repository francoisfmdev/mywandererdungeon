-- core/game/entity_manager.lua - Gestion positions et entites sur la carte
local M = {}

local EntityFactory = require("core.game.entity")

function M.new(map, defaultWeapon)
  local self = {}
  self._map = map
  self._entities = {}
  self._positions = {}
  self._defaultWeapon = defaultWeapon or { damageMin = 1, damageMax = 4, damageType = "slashing", statUsed = "strength" }

  function self:pos_key(x, y)
    return tostring(x) .. "," .. tostring(y)
  end

  function self:addEntity(entity, x, y)
    if not entity or not x or not y then return false end
    entity.x = x
    entity.y = y
    entity.gridX = x
    entity.gridY = y
    self._entities[entity.id] = entity
    local k = self:pos_key(x, y)
    if not self._positions[k] then self._positions[k] = {} end
    table.insert(self._positions[k], entity.id)
    return true
  end

  function self:removeEntity(entity)
    if not entity then return end
    self._entities[entity.id] = nil
    local k = self:pos_key(entity.x, entity.y)
    if self._positions[k] then
      for i, eid in ipairs(self._positions[k]) do
        if eid == entity.id then
          table.remove(self._positions[k], i)
          break
        end
      end
      if #self._positions[k] == 0 then self._positions[k] = nil end
    end
  end

  function self:moveEntity(entity, nx, ny)
    if not entity then return false end
    local ox, oy = entity.x, entity.y
    local ok = self:pos_key(ox, oy)
    if self._positions[ok] then
      for i, eid in ipairs(self._positions[ok]) do
        if eid == entity.id then
          table.remove(self._positions[ok], i)
          break
        end
      end
      if #self._positions[ok] == 0 then self._positions[ok] = nil end
    end
    entity.x, entity.y = nx, ny
    entity.gridX, entity.gridY = nx, ny
    local nk = self:pos_key(nx, ny)
    if not self._positions[nk] then self._positions[nk] = {} end
    table.insert(self._positions[nk], entity.id)
    return true
  end

  function self:getEntityAt(x, y)
    local k = self:pos_key(x, y)
    local ids = self._positions[k]
    if not ids or #ids == 0 then return nil end
    return self._entities[ids[1]]
  end

  function self:getBlockingEntityAt(x, y)
    return self:getEntityAt(x, y)
  end

  function self:getPlayer()
    for _, e in pairs(self._entities) do
      if e.isPlayer then return e end
    end
    return nil
  end

  function self:getAliveMonsters()
    local out = {}
    for _, e in pairs(self._entities) do
      if not e.isPlayer and (e.hp == nil or e.hp > 0) then
        table.insert(out, e)
      end
    end
    return out
  end

  function self:isEnemy(a, b)
    if not a or not b then return false end
    return (a.isPlayer and not b.isPlayer) or (not a.isPlayer and b.isPlayer)
  end

  function self:getEntity(id)
    return self._entities[id]
  end

  function self:getEntities()
    return self._entities
  end

  return self
end

return M
