-- core/targeting/target_selector.lua - Ciblage par direction, portee arme
local M = {}

local OCTO = {
  { dx = 0, dy = -1 },
  { dx = 1, dy = -1 },
  { dx = 1, dy = 0 },
  { dx = 1, dy = 1 },
  { dx = 0, dy = 1 },
  { dx = -1, dy = 1 },
  { dx = -1, dy = 0 },
  { dx = -1, dy = -1 },
}

--- Normalise (ex-px, ey-py) en direction 8-way (dx, dy) vers la cible.
function M.directionToward(px, py, ex, ey)
  if not px or not py or not ex or not ey then return 0, -1 end
  local adx = ex - px
  local ady = ey - py
  if adx == 0 and ady == 0 then return 0, -1 end
  local dx = (adx > 0) and 1 or ((adx < 0) and -1 or 0)
  local dy = (ady > 0) and 1 or ((ady < 0) and -1 or 0)
  if math.abs(adx) > math.abs(ady) then
    dy = 0
  elseif math.abs(ady) > math.abs(adx) then
    dx = 0
  end
  return dx, dy
end

--- Trouve l'ennemi le plus proche atteignable a la portee de l'arme.
--- Retourne (entity, dx, dy) ou (nil, defaultDx, defaultDy).
function M.findNearestEnemyInRange(px, py, range, map, entityManager, player)
  if not map or not entityManager or not player then return nil, 0, -1 end
  range = math.max(1, tonumber(range) or 1)
  local bestEntity, bestDx, bestDy, bestDist = nil, 0, -1, 9999

  for _, d in ipairs(OCTO) do
    for step = 1, range do
      local x = px + d.dx * step
      local y = py + d.dy * step
      if not map:inBounds(x, y) then break end
      if not map:isWalkable(x, y) then break end
      local entity = entityManager:getBlockingEntityAt(x, y)
      if entity and entityManager:isEnemy(player, entity) and (entity.hp == nil or entity.hp > 0) then
        if step < bestDist then
          bestDist = step
          bestEntity = entity
          bestDx, bestDy = d.dx, d.dy
        end
        break
      end
    end
  end
  return bestEntity, bestDx, bestDy
end

--- Pour sort projectile : cible (entity) ou derniere cellule dans la direction.
--- Retourne entity, ou si vide : { x = gx, y = gy } pour la position d'impact.
function M.findTargetOrCellInDirection(px, py, dx, dy, range, map, entityManager, attacker)
  if not map or not entityManager then return nil end
  if not px or not py then return nil end
  range = math.max(1, tonumber(range) or 1)
  local lastGx, lastGy = nil, nil

  for i = 1, range do
    local x = px + dx * i
    local y = py + dy * i
    if not map:inBounds(x, y) then break end
    if not map:isWalkable(x, y) then break end
    lastGx, lastGy = x, y
    local entity = entityManager:getBlockingEntityAt(x, y)
    if entity then
      if attacker and entityManager:isEnemy(attacker, entity) then
        return entity
      end
      if not attacker then return entity end
      return lastGx and lastGy and { x = lastGx, y = lastGy } or nil
    end
  end
  return lastGx and lastGy and { x = lastGx, y = lastGy } or nil
end

--- Cherche la premiere entite ennemie dans la direction (dx,dy) jusqu'a range.
--- S'arrete sur mur. Premier ennemi rencontre = cible.
function M.findTargetInDirection(px, py, dx, dy, range, map, entityManager, attacker)
  if not map or not entityManager then return nil end
  if not px or not py then return nil end
  range = math.max(1, tonumber(range) or 1)

  for i = 1, range do
    local x = px + dx * i
    local y = py + dy * i
    if not map:inBounds(x, y) then return nil end
    if not map:isWalkable(x, y) then return nil end

    local entity = entityManager:getBlockingEntityAt(x, y)
    if entity then
      if attacker and entityManager:isEnemy(attacker, entity) then
        return entity
      end
      if not attacker then return entity end
      return nil
    end
  end
  return nil
end

--- Verifie que (dx,dy) est une direction valide 8-way
function M.isValidDirection(dx, dy)
  if dx == nil or dy == nil then return false end
  if dx < -1 or dx > 1 or dy < -1 or dy > 1 then return false end
  return dx ~= 0 or dy ~= 0
end

return M
