-- core/turn/action_resolver.lua - Execution des actions (move, attack, cast, wait, use_item)
local M = {}

local octo = require("core.grid.octo_dirs")
local combat_resolver = require("core.combat.combat_resolver")
local TrapResolver = require("core.traps.trap_resolver")
local log_manager = require("core.game_log.log_manager")
local TrapRegistry = require("core.traps.trap_registry")
local spell_registry = require("core.spells.spell_registry")

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
      push_event(events, "effect", "log.effect.blocked_attack", {})
      log_manager.add("effect", { messageKey = "log.effect.blocked_attack", params = {} })
      return events, false
    end
    local defender = action.defender
    local weapon = action.weapon or attacker.weapon or gameState.defaultWeapon
    if not attacker or not defender or not weapon then return events, false end

    local i18n = require("core.i18n")
    local attName = attacker.nameKey and i18n.t(attacker.nameKey) or (attacker.name or "attacker")
    local defName = defender.nameKey and i18n.t(defender.nameKey) or (defender.name or "defender")
    if attacker._character then attName = i18n.t("log.trap.you") end
    if defender._character then defName = i18n.t("log.trap.you") end

    local result = combat_resolver.resolveAttack(attacker, defender, weapon)

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

  if actionType == "cast" then
    local caster = action.caster
    if is_action_blocked(caster, "cast") then
      push_event(events, "effect", "log.effect.blocked_cast", {})
      return events, false
    end
    local target = action.target
    local spellId = action.spellId
    if not caster or not spellId then return events, false end

    local spell = spell_registry.get(spellId)
    if not spell then return events, false end

    local i18n = require("core.i18n")
    local casterName = caster.nameKey and i18n.t(caster.nameKey) or (caster.name or "caster")
    if caster._character then casterName = i18n.t("log.trap.you") end

    local radius = tonumber(spell.radius) or 0
    if radius > 0 and entityManager then
      local cx = (target and (target.x or target.gridX)) or (caster.x or caster.gridX)
      local cy = (target and (target.y or target.gridY)) or (caster.y or caster.gridY)
      if cx and cy then
        local hits = combat_resolver.resolveSpellArea(caster, spell, cx, cy, entityManager)
        for _, h in ipairs(hits) do
          local t = h.target
          local targetName = t.nameKey and i18n.t(t.nameKey) or (t.name or "?")
          if t._character then targetName = i18n.t("log.trap.you") end
          if h.healed and h.healed > 0 then
            push_event(events, "spell", "log.spell.heal", {
              caster = casterName,
              target = targetName,
              amount = h.healed,
            })
          elseif h.damage and h.damage > 0 then
            push_event(events, "spell", "log.spell.damage", {
              caster = casterName,
              target = targetName,
              damage = h.damage,
            })
          end
        end
        return events, true
      end
    end

    local result = combat_resolver.resolveSpell(caster, target, spell)
    local targetName = target and (target.nameKey and i18n.t(target.nameKey) or target.name) or "self"
    if target and target._character then targetName = i18n.t("log.trap.you") end

    if result.hit and (result.damage > 0 or result.healed > 0) then
      if result.healed > 0 then
        push_event(events, "spell", "log.spell.heal", {
          caster = casterName,
          target = targetName,
          amount = result.healed,
        })
      else
        push_event(events, "spell", "log.spell.damage", {
          caster = casterName,
          target = targetName,
          damage = result.damage,
        })
      end
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
      push_event(events, "effect", "log.effect.blocked_use_item", {})
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
        require("core.player_data").remove_item(itemIndex)
      end
    end
    return events, true
  end

  return events, false
end

return M
