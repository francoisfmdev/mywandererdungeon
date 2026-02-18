-- core/consumables/consumable_effects.lua - Application des effets (potions, wands, cartes)
local M = {}

local ConsumableRegistry = require("core.consumables.consumable_registry")
local combat_resolver = require("core.combat.combat_resolver")
local spell_registry = require("core.spells.spell_registry")

function M.applyPotion(item, entity, events, gameState)
  local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
  if not def or def.type ~= "potion" then return false end

  local effect = def.effect
  local amount = def.amount or 0
  local push = function(t, k, p)
    table.insert(events, { type = t, messageKey = k, params = p or {} })
  end

  if effect == "heal_hp" and amount > 0 and entity then
    local maxHp = entity.maxHp or (entity._character and entity._character:getMaxHP()) or 1
    local cur = entity.hp or 0
    local healed = math.min(amount, math.max(0, maxHp - cur))
    if healed > 0 then
      entity.hp = cur + healed
      if entity._character and entity._character.setHP then
        entity._character:setHP(entity.hp)
      end
      push("item", "log.item.heal_hp", { amount = healed })
      return true
    end
  elseif effect == "heal_mp" and amount > 0 and entity then
    local maxMp = entity.maxMp or (entity._character and entity._character:getMaxMP()) or 0
    local cur = entity.mp or 0
    local healed = math.min(amount, math.max(0, maxMp - cur))
    if healed > 0 then
      entity.mp = cur + healed
      if entity._character and entity._character.setMP then
        entity._character:setMP(entity.mp)
      end
      push("item", "log.item.heal_mp", { amount = healed })
      return true
    end
  elseif effect == "cure_effect" and def.cureEffect and entity and entity.effectManager then
    if entity.effectManager:hasEffect(def.cureEffect) then
      entity.effectManager:removeEffect(def.cureEffect)
      local i18n = require("core.i18n")
      local effectName = i18n.t("log.effect." .. def.cureEffect) or def.cureEffect
      push("item", "log.item.cure_effect", { effect = effectName })
      return true
    end
  end
  return false
end

function M.applyWand(item, caster, target, events, gameState)
  local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
  if not def or def.type ~= "wand" then return false end

  local charges = item.charges or def.chargesMax or 1
  if charges <= 0 then return false end

  local spellId = def.spellId
  local spell = spell_registry.get(spellId)
  if not spell then return false end

  local wandOpt = { skipMpCost = true }
  local result
  local radius = tonumber(spell.radius) or 0
  if radius > 0 and gameState and gameState.entityManager then
    local cx = (target and (target.x or target.gridX)) or (caster.x or caster.gridX)
    local cy = (target and (target.y or target.gridY)) or (caster.y or caster.gridY)
    if cx and cy then
      result = combat_resolver.resolveSpellArea(caster, spell, cx, cy, gameState.entityManager, wandOpt)
    end
  else
    local t = target or caster
    result = combat_resolver.resolveSpell(caster, t, spell, wandOpt)
  end

  if result and (result.hit or (type(result) == "table" and #result > 0)) then
    local hadEffect = result.hit or (type(result) == "table" and #result > 0)
    if hadEffect then
      item.charges = charges - 1
      if item.charges <= 0 then item._consumed = true end
      local i18n = require("core.i18n")
      local name = def.nameKey and i18n.t(def.nameKey) or def.id
      table.insert(events, { type = "item", messageKey = "log.item.wand_used", params = { item = name, charges = item.charges or 0 } })
      return true
    end
  end
  return false
end

function M.applyCard(item, caster, targetEntity, targetGx, targetGy, events, gameState)
  local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
  if not def or def.type ~= "card" then return false end

  local map = gameState and gameState.map
  local entityManager = gameState and gameState.entityManager
  if not map or not entityManager then return false end

  local push = function(t, k, p)
    table.insert(events, { type = t, messageKey = k, params = p or {} })
  end

  if def.effect == "teleport" then
    local floorTiles = {}
    for x = 1, map.width do
      for y = 1, map.height do
        if map:isWalkable(x, y) then
          local ent = entityManager:getEntityAt(x, y)
          if not ent or ent == targetEntity then
            table.insert(floorTiles, { x, y })
          end
        end
      end
    end

    if #floorTiles == 0 then return false end

    local dest = floorTiles[math.random(1, #floorTiles)]
    local tx, ty = dest[1], dest[2]

    if targetEntity then
      entityManager:moveEntity(targetEntity, tx, ty)
      local i18n = require("core.i18n")
      local name = targetEntity.nameKey and i18n.t(targetEntity.nameKey) or (targetEntity.name or "?")
      push("item", "log.item.card_teleport_monster", { target = name })
    else
      local player = entityManager:getPlayer()
      if player then
        entityManager:moveEntity(player, tx, ty)
        player.x, player.y = tx, ty
        player.gridX, player.gridY = tx, ty
        map:exploreAround(tx, ty, 6)
        push("item", "log.item.card_teleport_self", {})
      end
    end
    item._consumed = true
    return true
  end
  return false
end

function M.applyIdentify(item, entity, events, gameState)
  local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
  if not def or def.type ~= "scroll" or def.effect ~= "identify" then return false end

  local player_data = require("core.player_data")
  local identified = 0

  for _, it in ipairs(player_data.get_inventory()) do
    if it.base and it.identified == false then
      it.identified = true
      identified = identified + 1
    end
  end

  local char = entity and entity._character
  if char and char.equipmentManager then
    for _, eq in pairs(char.equipmentManager:getAllEquipped()) do
      if eq and eq.base and eq.identified == false then
        eq.identified = true
        identified = identified + 1
      end
    end
  end

  if identified > 0 then
    local push = function(t, k, p)
      table.insert(events, { type = t, messageKey = k, params = p or {} })
    end
    push("item", "log.item.identify_done", { count = identified })
  end
  item._consumed = true
  return true
end

function M.applyPurify(item, entity, events, gameState)
  local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
  if not def or def.type ~= "card" or def.effect ~= "purify" then return false end

  local player_data = require("core.player_data")
  local purified = 0

  for _, it in ipairs(player_data.get_inventory()) do
    if it and it.cursed then
      it.cursed = false
      purified = purified + 1
    end
  end

  local char = entity and entity._character
  if char and char.equipmentManager then
    for _, eq in pairs(char.equipmentManager:getAllEquipped()) do
      if eq and eq.cursed then
        eq.cursed = false
        purified = purified + 1
      end
    end
  end

  if purified > 0 then
    local push = function(t, k, p)
      table.insert(events, { type = t, messageKey = k, params = p or {} })
    end
    push("item", "log.item.purify_done", { count = purified })
  end
  item._consumed = true
  return true
end

return M
