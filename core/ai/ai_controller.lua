-- core/ai/ai_controller.lua - FSM IA monstres, retourne action structuree
local M = {}

local pathfinding = require("core.ai.pathfinding")

--- gameState: { map, entityManager, turnNumber }
--- Retourne { type, ... } ou nil
function M.update(monster, gameState)
  if not monster or not gameState then return { type = "wait" } end
  if monster.hp and monster.hp <= 0 then return nil end

  local map = gameState.map
  local entityManager = gameState.entityManager
  if not map or not entityManager then return { type = "wait" } end

  local player = entityManager:getPlayer()
  if not player or (player.hp and player.hp <= 0) then return { type = "wait" } end

  local mx, my = monster.x or monster.gridX, monster.y or monster.gridY
  local px, py = player.x or player.gridX, player.y or player.gridY
  if not mx or not my or not px or not py then return { type = "wait" } end

  local function can_walk(x, y)
    if not map:inBounds(x, y) then return false end
    if x == px and y == py then return true end
    if not map:isWalkable(x, y) then return false end
    local blocker = entityManager:getBlockingEntityAt(x, y)
    return blocker == nil
  end

  local dist = math.max(math.abs(px - mx), math.abs(py - my))
  if dist <= 1 then
    return {
      type = "attack",
      attacker = monster,
      defender = player,
      targetId = player.id,
      weapon = monster.weapon,
    }
  end

  local dx, dy = pathfinding.first_step_toward(map, mx, my, px, py, can_walk)
  if dx and dy then
    return {
      type = "move",
      entity = monster,
      dx = dx,
      dy = dy,
    }
  end

  return { type = "wait" }
end

return M
