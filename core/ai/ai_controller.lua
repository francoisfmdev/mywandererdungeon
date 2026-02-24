-- core/ai/ai_controller.lua - FSM IA monstres (data-driven via data/ai/behaviors.lua)
local M = {}

local pathfinding = require("core.ai.pathfinding")
local MonsterRegistry = require("core.entities.monster_registry")
local AIRegistry = require("core.ai.ai_registry")

local IDLE = "idle"
local ALERT = "alert"
local HUNTING = "hunting"
local FLEEING = "fleeing"
local ATTACKING = "attacking"

local function has_fear(entity)
  return entity.effectManager and entity.effectManager.hasFear and entity.effectManager:hasFear()
end

local function get_pos(entity)
  return entity.x or entity.gridX, entity.y or entity.gridY
end

local function chebyshev_dist(ax, ay, bx, by)
  return math.max(math.abs(bx - ax), math.abs(by - ay))
end

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

  local mx, my = get_pos(monster)
  local px, py = get_pos(player)
  if not mx or not my or not px or not py then return { type = "wait" } end

  local dist = chebyshev_dist(mx, my, px, py)
  local monsterDef = (monster.monsterId and MonsterRegistry.get(monster.monsterId)) or {}
  local ai = AIRegistry.getEffectiveConfig(monsterDef)

  local detectionRadius = ai.detectionRadius
  local attackRange = ai.attackRange
  local fleeOnFear = ai.fleeOnFear
  local fleeOnLowHp = ai.fleeOnLowHp
  local hpFleeThreshold = ai.hpFleeThreshold
  local chasePlayer = ai.chasePlayer
  local waitChance = ai.waitChance
  local keepDistance = ai.keepDistance
  local idealRange = ai.idealRange
  local idleBehavior = ai.idleBehavior or "none"
  local patrolRadius = tonumber(ai.patrolRadius) or 3
  local wanderChance = tonumber(ai.wanderChance) or 0.5

  local state = monster.aiState or IDLE

  local function can_walk(x, y)
    if not map:inBounds(x, y) then return false end
    if x == px and y == py then return true end
    if not map:isWalkable(x, y) then return false end
    local blocker = entityManager:getBlockingEntityAt(x, y)
    return blocker == nil
  end

  local function can_walk_flee(x, y)
    if not map:inBounds(x, y) then return false end
    if not map:isWalkable(x, y) then return false end
    local blocker = entityManager:getBlockingEntityAt(x, y)
    return blocker == nil
  end

  -- Fuir si peur (fleeOnFear)
  if fleeOnFear and has_fear(monster) then
    monster.aiState = FLEEING
    local dx, dy = pathfinding.first_step_away(map, mx, my, px, py, can_walk_flee)
    if dx and dy then
      return { type = "move", entity = monster, dx = dx, dy = dy }
    end
    return { type = "wait" }
  end

  -- Fuir si PV bas (fleeOnLowHp)
  if fleeOnLowHp and monster.maxHp and monster.maxHp > 0 then
    local ratio = (monster.hp or 0) / monster.maxHp
    if ratio <= hpFleeThreshold then
      monster.aiState = FLEEING
      local dx, dy = pathfinding.first_step_away(map, mx, my, px, py, can_walk_flee)
      if dx and dy then
        return { type = "move", entity = monster, dx = dx, dy = dy }
      end
      return { type = "wait" }
    end
  end

  -- Hors portee detection : IDLE avec wander ou patrol
  if dist > detectionRadius then
    monster.aiState = IDLE
    if (idleBehavior == "wander" or idleBehavior == "patrol") and wanderChance > 0 and math.random() < wanderChance then
      local octo = require("core.grid.octo_dirs")
      local candidates = {}
      for _, d in octo.each_dir() do
        local nx, ny = mx + d.dx, my + d.dy
        if map:inBounds(nx, ny) and map:isWalkable(nx, ny) then
          local blocker = entityManager:getBlockingEntityAt(nx, ny)
          if not blocker then
            if idleBehavior == "wander" then
              table.insert(candidates, { d.dx, d.dy })
            else
              local sx = monster.spawnX or mx
              local sy = monster.spawnY or my
              local distFromSpawn = math.max(math.abs(nx - sx), math.abs(ny - sy))
              if distFromSpawn <= patrolRadius then
                table.insert(candidates, { d.dx, d.dy })
              end
            end
          end
        end
      end
      if #candidates > 0 then
        local pick = candidates[math.random(1, #candidates)]
        return { type = "move", entity = monster, dx = pick[1], dy = pick[2] }
      end
    end
    return { type = "wait" }
  end

  if state == IDLE then
    monster.aiState = ALERT
  end

  -- Attaque si a portee (attackRange depuis config)
  if dist <= attackRange then
    local behavior = ATTACKING
    if keepDistance and dist > 1 and idealRange and dist >= idealRange then
      behavior = HUNTING
    end
    local attacks = monsterDef.attacksByBehavior and monsterDef.attacksByBehavior[behavior]
    if (not attacks or #attacks == 0) and behavior ~= ATTACKING then
      attacks = monsterDef.attacksByBehavior and monsterDef.attacksByBehavior[ATTACKING]
    end
    if attacks and #attacks > 0 then
      if waitChance > 0 and math.random() < waitChance then
        return { type = "wait" }
      end
      monster.aiState = ATTACKING
      return {
        type = "attack",
        attacker = monster,
        defender = player,
        targetId = player.id,
        behavior = behavior,
      }
    end
  end

  -- keepDistance : archer trop proche, reculer
  if keepDistance and dist < idealRange and dist > 1 then
    local dx, dy = pathfinding.first_step_away(map, mx, my, px, py, can_walk_flee)
    if dx and dy then
      monster.aiState = HUNTING
      return { type = "move", entity = monster, dx = dx, dy = dy }
    end
  end

  -- Poursuite (chasePlayer)
  if not chasePlayer then
    return { type = "wait" }
  end

  monster.aiState = HUNTING
  local dx, dy = pathfinding.first_step_toward(map, mx, my, px, py, can_walk)
  if dx and dy then
    return { type = "move", entity = monster, dx = dx, dy = dy }
  end

  return { type = "wait" }
end

return M
