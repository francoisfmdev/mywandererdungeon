-- core/turn/turn_manager.lua - Boucle de tour complete (action joueur, monstres, effets, pieges, morts)
local M = {}

local ActionResolver = require("core.turn.action_resolver")
local AIController = require("core.ai.ai_controller")
local DeathHandler = require("core.game.death_handler")
local log_manager = require("core.game_log.log_manager")
local WeaponRegistry = require("core.weapons.weapon_registry")
local EntityFactory = require("core.game.entity")

local function push_event(events, type, messageKey, params)
  table.insert(events, {
    type = type,
    messageKey = messageKey or "log.info.unknown",
    params = params or {},
  })
end

local function apply_effect_phase(entity, turnNumber, events)
  if not entity or not entity.effectManager then return end
  local hookResults = entity.effectManager:updateTurnStart(turnNumber)
  if hookResults and #hookResults > 0 then
    local i18n = require("core.i18n")
    local targetName = entity.nameKey and i18n.t(entity.nameKey) or (entity.name or "?")
    if entity._character then targetName = i18n.t("log.trap.you") end
    for _, hr in ipairs(hookResults) do
      if hr.result and (hr.result.damage or 0) > 0 then
        local effectName = i18n.t("log.effect." .. (hr.effectId or "?"))
        if effectName:find("^%[%[missing") then effectName = hr.effectId or "?" end
        push_event(events, "effect", "log.effect.damage", {
          target = targetName,
          effect = effectName,
          damage = hr.result.damage,
        })
      end
    end
  end
  entity.effectManager:updateTurnEnd(turnNumber)
end

local function weighted_random_monster(monsters)
  if not monsters or #monsters == 0 then return nil end
  local total = 0
  for _, m in ipairs(monsters) do total = total + (m.weight or 1) end
  if total <= 0 then return monsters[1] and monsters[1].id end
  local r = math.random() * total
  for _, m in ipairs(monsters) do
    r = r - (m.weight or 1)
    if r <= 0 then return m.id end
  end
  return monsters[#monsters] and monsters[#monsters].id
end

local function try_spawn_monster_far_from_player(gameState)
  local dungeonConfig = gameState.dungeonConfig
  if not dungeonConfig then return end
  local gen = dungeonConfig.generation or {}
  local chance = gen.spawnChanceEvery5Turns or 0.08
  local minDist = gen.spawnMinDistanceFromPlayer or 12
  if math.random() >= chance then return end

  local map = gameState.map
  local entityManager = gameState.entityManager
  local player = entityManager and entityManager:getPlayer()
  if not map or not entityManager or not player then return end

  local px, py = player.x or player.gridX, player.y or player.gridY
  if not px or not py then return end

  local monsters = dungeonConfig.monsters or {}
  if #monsters == 0 then return end

  local candidates = {}
  for gx = 1, map.width do
    for gy = 1, map.height do
      if map:isWalkable(gx, gy) and not entityManager:getEntityAt(gx, gy) then
        local dist = math.abs(gx - px) + math.abs(gy - py)
        if dist >= minDist then
          table.insert(candidates, { gx, gy })
        end
      end
    end
  end
  if #candidates == 0 then return end

  local pos = candidates[math.random(1, #candidates)]
  local monsterId = weighted_random_monster(monsters)
  if not monsterId then return end

  local monster = EntityFactory.createMonster(monsterId, pos[1], pos[2])
  if monster and entityManager:addEntity(monster, pos[1], pos[2]) then
    return monsterId
  end
  return nil
end

function M.update(playerAction, gameState)
  local events = {}
  if not gameState then return { events = events, gameOver = false } end

  local map = gameState.map
  local entityManager = gameState.entityManager
  local turnNumber = gameState.turnNumber or 0
  local player = entityManager and entityManager:getPlayer()

  if not player then
    return { events = events, gameOver = gameState.gameOver or false }
  end

  if not playerAction or playerAction.type == "invalid" then
    return { events = events, turnNumber = gameState.turnNumber or 0, gameOver = false }
  end

  turnNumber = (gameState.turnNumber or 0) + 1
  gameState.turnNumber = turnNumber
  log_manager.set_turn(turnNumber)

  local actionType = playerAction.type
  local resolved = false
  if actionType == "move" then
    local dx, dy = playerAction.dx or 0, playerAction.dy or 0
    if dx ~= 0 or dy ~= 0 then
      local _, consumed = ActionResolver.execute({
        type = "move",
        entity = player,
        dx = dx,
        dy = dy,
      }, gameState, events)
      resolved = consumed
    end
  elseif actionType == "attack" then
    local target = playerAction.targetId and entityManager:getEntity(playerAction.targetId)
    if target then
      local weapon = playerAction.weapon
      if not weapon and player._character and player._character.equipmentManager then
        local item = player._character.equipmentManager:getEquipped("weapon_main")
        if item then weapon = item.base or item end
      end
      if not weapon or (not weapon.damageMin and not weapon.damageMax) then
        weapon = WeaponRegistry.get(gameState.defaultWeaponId or "dagger") or gameState.defaultWeapon
      end
      local _, consumed = ActionResolver.execute({
        type = "attack",
        attacker = player,
        defender = target,
        weapon = weapon,
      }, gameState, events)
      resolved = consumed
    end
  elseif actionType == "cast" then
    local target = playerAction.targetId and entityManager:getEntity(playerAction.targetId)
    local _, consumed = ActionResolver.execute({
      type = "cast",
      caster = player,
      target = target,
      spellId = playerAction.spellId,
    }, gameState, events)
    resolved = consumed
  elseif actionType == "wait" then
    local _, consumed = ActionResolver.execute({ type = "wait" }, gameState, events)
    resolved = consumed
  elseif actionType == "use_item" then
    local _, consumed = ActionResolver.execute({
      type = "use_item",
      entity = player,
      itemIndex = playerAction.itemIndex,
      targetEntity = playerAction.targetEntity,
      targetGx = playerAction.targetGx,
      targetGy = playerAction.targetGy,
    }, gameState, events)
    resolved = consumed
  end

  if not resolved then
    gameState.turnNumber = turnNumber - 1
    log_manager.set_turn(gameState.turnNumber)
    for _, e in ipairs(events) do
      log_manager.add(e.type or "info", { messageKey = e.messageKey, params = e.params or {} })
    end
    return { events = events, turnNumber = gameState.turnNumber, gameOver = false }
  end

  apply_effect_phase(player, turnNumber, events)

  -- Regen PV/PM (style Shiren) - joueur uniquement, bloquee si exténué
  local char = player._character
  local blockRegen = player.effectManager and player.effectManager:getBlockRegen()
  if char and not blockRegen then
    local cfg = char._config
    if cfg then
      local con = char:getEffectiveStat("constitution") or 0
      local int = char:getEffectiveStat("intelligence") or 0
      local hpDiv = tonumber(cfg.hpRegenPerCon) or 4
      local mpDiv = tonumber(cfg.mpRegenPerInt) or 4
      local hpRegen = math.floor(con / hpDiv)
      local mpRegen = math.floor(int / mpDiv)
      local maxHp = char:getMaxHP()
      local maxMp = char:getMaxMP()
      if hpRegen > 0 and (player.hp or 0) < maxHp then
        player.hp = math.min((player.hp or 0) + hpRegen, maxHp)
        if char.setHP then char:setHP(player.hp) end
      end
      if mpRegen > 0 and (player.mp or 0) < maxMp then
        player.mp = math.min((player.mp or 0) + mpRegen, maxMp)
        if char.setMP then char:setMP(player.mp) end
      end
    end
  end

  DeathHandler.processDeaths(entityManager, events, gameState)
    if (player.hp or 0) <= 0 then
      gameState.gameOver = true
      gameState.death = true
      for _, e in ipairs(events) do
        log_manager.add(e.type or "info", { messageKey = e.messageKey, params = e.params or {} })
      end
      return { events = events, turnNumber = turnNumber, gameOver = true, death = true }
    end

    local monsters = entityManager:getAliveMonsters()
    for _, monster in ipairs(monsters) do
      local action = AIController.update(monster, gameState)
      if action then
        ActionResolver.execute(action, gameState, events)
        -- Les pieges ne se declenchent que pour le joueur (dans action_resolver move)
        apply_effect_phase(monster, turnNumber, events)
      end
    end
    DeathHandler.processDeaths(entityManager, events, gameState)

    if (player.hp or 0) <= 0 then
      gameState.gameOver = true
      gameState.death = true
    end

  if turnNumber >= 5 and turnNumber % 5 == 0 then
    local monsterId = try_spawn_monster_far_from_player(gameState)
    if monsterId then
      local i18n = require("core.i18n")
      local MonsterRegistry = require("core.entities.monster_registry")
      local def = MonsterRegistry.get(monsterId)
      local name = def and def.nameKey and i18n.t(def.nameKey) or monsterId
      if name and name:find("^%[%[missing") then name = monsterId end
      push_event(events, "spawn", "log.spawn.monster", { monster = name })
      log_manager.add("spawn", { messageKey = "log.spawn.monster", params = { monster = name } })
    end
  end

  for _, e in ipairs(events) do
    log_manager.add(e.type or "info", { messageKey = e.messageKey, params = e.params or {} })
  end

  return {
    events = events,
    turnNumber = turnNumber,
    gameOver = gameState.gameOver or false,
    death = gameState.death or false,
  }
end

return M
