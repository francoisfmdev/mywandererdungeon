-- core/turn/action_resolver.lua - Execution des actions (move, attack, cast, wait, use_item)
local M = {}

local octo = require("core.grid.octo_dirs")
local combat_resolver = require("core.combat.combat_resolver")
local TrapResolver = require("core.traps.trap_resolver")
local log_manager = require("core.game_log.log_manager")

local function push_event(events, type, messageKey, params)
  table.insert(events, {
    type = type,
    messageKey = messageKey or "log.info.unknown",
    params = params or {},
  })
end

local function trigger_trap_at(tile, entity, events)
  if not tile or not tile.trap or not entity then return false end
  local trap = tile.trap
  if trap.triggered then return false end

  local i18n = require("core.i18n")
  local entityName = entity.nameKey and i18n.t(entity.nameKey) or (entity.name or "entity")
  if entity._character then
    entityName = i18n.t("log.trap.you")
  end

  TrapResolver.trigger(trap, entity)
  push_event(events, "trap", "log.trap.trigger", { target = entityName })
  if trap.oneShot and trap.triggered then
    trap.state = "triggered"
  end
  return true
end

function M.execute(action, gameState, events)
  events = events or {}
  if not action or not gameState then return events, false end

  local map = gameState.map
  local entityManager = gameState.entityManager
  if not map or not entityManager then return events, false end

  local actionType = action.type
  local function is_action_blocked(entity, actionKind)
    if not entity or not entity.effectManager then return false end
    local blocked = entity.effectManager:getBlockedActions()
    return blocked[actionKind]
  end

  if actionType == "move" then
    local entity = action.entity
    if is_action_blocked(entity, "move") then
      push_event(events, "effect", "log.effect.blocked_move", {})
      return events, false
    end
    local dx, dy = action.dx or 0, action.dy or 0
    if not entity or (dx == 0 and dy == 0) then return events, false end

    local valid_dir = false
    for _, d in octo.each_dir() do
      if d.dx == dx and d.dy == dy then
        valid_dir = true
        break
      end
    end
    if not valid_dir then return events, false end

    local x, y = entity.x or entity.gridX, entity.y or entity.gridY
    if not x or not y then return events, false end

    local nx, ny = x + dx, y + dy
    if not map:inBounds(nx, ny) then return events, false end

    local blocker = entityManager:getBlockingEntityAt(nx, ny)
    if blocker and blocker ~= entity then
      push_event(events, "blocked", "log.player.blocked", {})
      return events, false
    end

    if not map:isWalkable(nx, ny) then return events, false end

    -- Attaque d'opportunite : si le joueur recule face a un monstre adjacent, celui-ci attaque
    if entity._character then
      local function cheb_dist(ax, ay, bx, by)
        return math.max(math.abs(bx - ax), math.abs(by - ay))
      end
      local monsters = entityManager:getAliveMonsters()
      for _, monster in ipairs(monsters) do
        if monster.hp and monster.hp > 0 then
          local mx = monster.x or monster.gridX
          local my = monster.y or monster.gridY
          if mx and my then
            local dist_old = cheb_dist(mx, my, x, y)
            local dist_new = cheb_dist(mx, my, nx, ny)
            if dist_old <= 1 and dist_new > dist_old then
              local result = combat_resolver.resolveAttack(monster, entity, nil, { behavior = "attacking" })
              local i18n = require("core.i18n")
              local attName = monster.nameKey and i18n.t(monster.nameKey) or (monster.name or "?")
              local defName = i18n.t("log.trap.you")
              if result.hit then
                local key = result.critical and "log.attack.crit" or "log.attack.hit"
                push_event(events, "attack", key, { attacker = attName, defender = defName, damage = result.damage or 0 })
                log_manager.add("attack", { messageKey = key, params = { attacker = attName, defender = defName, damage = result.damage or 0 } })
              else
                push_event(events, "attack", "log.attack.miss", { attacker = attName, defender = defName })
                log_manager.add("attack", { messageKey = "log.attack.miss", params = { attacker = attName, defender = defName } })
              end
              break
            end
          end
        end
      end
    end

    entityManager:moveEntity(entity, nx, ny)
    entity.x, entity.y = nx, ny
    entity.gridX, entity.gridY = nx, ny

    if entity._character then
      map:exploreAround(nx, ny, 6)
      if entity._syncEffectEntityFromChar then
        entity:_syncEffectEntityFromChar()
      end
    end

    local tile = map:getTile(nx, ny)
    if tile and tile.trap and not tile.trap.triggered then
      trigger_trap_at(tile, entity, events)
    end

    if entity._character then
      -- Marche sur la sortie : passage a l'etage suivant (si pas dernier etage)
      local exit = gameState.exit
      if exit and nx == exit.x and ny == exit.y then
        local currentFloor = gameState.currentFloor or 1
        local totalFloors = gameState.totalFloors or 1
        if currentFloor < totalFloors then
          return events, true, { reachedExit = true, nextFloor = true }
        end
      end

      local gold, items = map:getGroundLoot(nx, ny)
      local player_data = require("core.player_data")
      if gold > 0 then
        player_data.add_gold(gold)
        push_event(events, "loot", "log.loot.gold", { amount = gold })
        log_manager.add("loot", { messageKey = "log.loot.gold", params = { amount = gold } })
        map:setGroundGold(nx, ny, 0)
      end
      if items and #items > 0 then
        local dungeon_run_state = require("core.dungeon_run_state")
        dungeon_run_state.setPendingGroundLoot(nx, ny)
      end
    end

    push_event(events, "move", "log.move.done", {})
    return events, true
  end

  if actionType == "attack" then
    local attacker = action.attacker
    if is_action_blocked(attacker, "attack") then
      local msgKey = (attacker.effectManager and attacker.effectManager.hasFear and attacker.effectManager:hasFear())
        and "log.effect.blocked_attack_fear" or "log.effect.blocked_attack"
      push_event(events, "effect", msgKey, {})
      log_manager.add("effect", { messageKey = msgKey, params = {} })
      return events, false
    end
    local defender = action.defender
    local isPlayer = attacker._character ~= nil
    local weapon = nil
    local attackOptions = {}
    if isPlayer then
      weapon = action.weapon or (attacker.equipmentManager and attacker.equipmentManager:getEquipped("weapon_main"))
      local equip = weapon and weapon.equipment
      weapon = (equip and equip.base) or weapon
      weapon = weapon or gameState.defaultWeapon
    else
      attackOptions.behavior = action.behavior or "attacking"
    end
    if not attacker or not defender then return events, false end
    if isPlayer and not weapon then return events, false end

    -- Verifier et consommer munitions (arc, arbalete, gun) ou arme de jet (joueur uniquement)
    local weaponData = weapon and (weapon.base or weapon)
    local ammoType = weaponData and weaponData.ammoType
    local ammoId = weaponData and (weaponData.ammoId or weaponData.id)
    if ammoType and ammoId and attacker._character then
      local player_data = require("core.player_data")
      local hasAmmo = false
      local consumeFromEquipment = false
      if ammoType == "throwing" then
        -- Arme de jet : consomme l'arme equipee elle-meme (1 par tir)
        hasAmmo = true
        consumeFromEquipment = true
      else
        -- Arc / arbalete / gun : munitions en inventaire
        hasAmmo = (player_data.count_ammo(ammoId) or 0) > 0
      end
      if not hasAmmo then
        local i18n = require("core.i18n")
        local ConsumableRegistry = require("core.consumables.consumable_registry")
        local ammoDef = ConsumableRegistry.get(ammoId)
        local ammoName = ammoDef and ammoDef.nameKey and i18n.t(ammoDef.nameKey)
          or i18n.t("item.equipment." .. ammoId) or ammoId
        push_event(events, "attack", "log.attack.no_ammo", { ammo = ammoName })
        log_manager.add("attack", { messageKey = "log.attack.no_ammo", params = { ammo = ammoName } })
        return events, false
      end
      if consumeFromEquipment then
        local slot = "weapon_main"
        local em = attacker.equipmentManager
        if em and em:getEquipped(slot) then
          em:unequip(slot)
        end
      else
        player_data.consume_one_ammo(ammoId)
      end
    end

    local i18n = require("core.i18n")
    local attName = attacker.nameKey and i18n.t(attacker.nameKey) or (attacker.name or "attacker")
    local defName = defender.nameKey and i18n.t(defender.nameKey) or (defender.name or "defender")
    if attacker._character then attName = i18n.t("log.trap.you") end
    if defender._character then defName = i18n.t("log.trap.you") end

    local result = combat_resolver.resolveAttack(attacker, defender, weapon, attackOptions)

    if result.hit then
      local key = result.critical and (attacker._character and "log.attack.player_crit" or "log.attack.crit")
        or (attacker._character and "log.attack.player_hit" or "log.attack.hit")
      local params = { attacker = attName, defender = defName, damage = result.damage or 0 }
      push_event(events, "attack", key, params)
      log_manager.add("attack", { messageKey = key, params = params })
    else
      local key = attacker._character and "log.attack.player_miss" or "log.attack.miss"
      local params = { attacker = attName, defender = defName }
      push_event(events, "attack", key, params)
      log_manager.add("attack", { messageKey = key, params = params })
    end
    return events, true
  end

  if actionType == "wait" then
    push_event(events, "wait", "log.wait.done", {})
    return events, true
  end

  if actionType == "use_item" then
    local player = entityManager:getPlayer()
    if is_action_blocked(player, "useItem") then
      local msgKey = (player.effectManager and player.effectManager.hasFear and player.effectManager:hasFear())
        and "log.effect.blocked_use_item_fear" or "log.effect.blocked_use_item"
      push_event(events, "effect", msgKey, {})
      return events, false
    end
    local itemIndex = action.itemIndex
    local targetEntity = action.targetEntity
    local targetGx, targetGy = action.targetGx, action.targetGy
    local inv = require("core.player_data").get_inventory()
    local item = itemIndex and inv[itemIndex]

    if not item or not player then
      return events, false
    end

    local ConsumableRegistry = require("core.consumables.consumable_registry")
    local ConsumableEffects = require("core.consumables.consumable_effects")
    local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))

    if not def then
      push_event(events, "item", "log.item.used", { item = item.id or "?" })
      return events, true
    end

    local applied = false
    if def.type == "potion" then
      applied = ConsumableEffects.applyPotion(item, player, events, gameState)
      if def.effect == "cure_effect" and not applied then
        push_event(events, "item", "log.item.cure_no_effect", {})
        return events, false
      end
    elseif def.type == "scroll" and def.effect == "identify" then
      applied = ConsumableEffects.applyIdentify(item, player, events, gameState)
    elseif def.type == "card" and def.effect == "purify" then
      applied = ConsumableEffects.applyPurify(item, player, events, gameState)
    elseif def.type == "wand" then
      applied = ConsumableEffects.applyWand(item, player, targetEntity, events, gameState)
    elseif def.type == "card" then
      applied = ConsumableEffects.applyCard(item, player, targetEntity, targetGx, targetGy, events, gameState)
    end

    if applied then
      if item._consumed or (def.type == "potion") or (def.type == "scroll") or (def.type == "card") then
        local player_data = require("core.player_data")
        if item.count and item.count > 1 then
          item.count = item.count - 1
        else
          player_data.remove_item(itemIndex)
        end
      end
    end
    return events, true
  end

  return events, false
end

return M
