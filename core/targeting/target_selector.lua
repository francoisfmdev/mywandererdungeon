-- core/targeting/target_selector.lua - Ciblage par direction, portee arme
local M = {}

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
