-- core/traps/trap_resolver.lua - Resolution des pieges au declenchement
local M = {}

local damage_calculator = require("core.combat.damage_calculator")
local log_manager = require("core.game_log.log_manager")

function M.trigger(trap, entity)
  if not trap or trap.triggered then return end

  local effect = trap.effect or {}
  local i18n = require("core.i18n")
  local entityName = "entity"
  if entity then
    if entity._character then
      entityName = i18n.t("log.trap.you")
    elseif entity.nameKey then
      entityName = i18n.t(entity.nameKey)
    else
      entityName = entity.name or "entity"
    end
  end

  if (effect.damageMin or effect.damageMax) then
    local baseDamage = damage_calculator.rollMinMax(effect.damageMin or 1, effect.damageMax or 1)
    local damageType = effect.damageType or "physical"
    local resist = { damage = baseDamage, healed = 0 }
    if entity then
      resist = damage_calculator.applyResistance(baseDamage, damageType, entity)
    end
    local finalDamage = resist.damage or 0
    if finalDamage > 0 and entity then
      if entity.setHP and entity.getHP then
        entity:setHP(math.max(0, entity:getHP() - finalDamage))
      elseif entity.hp ~= nil then
        entity.hp = math.max(0, (entity.hp or 0) - finalDamage)
        if entity._character and entity._character.setHP then
          entity._character:setHP(entity.hp)
        end
      end
      entity.shakeFrames = 12
    end
    log_manager.add("trap", {
      messageKey = "log.trap.damage",
      params = { target = entityName, damage = finalDamage },
    })
  end

  if effect.applyEffect and entity and entity.effectManager then
    local turnNumber = 0
    if log_manager.get_turn then
      turnNumber = log_manager.get_turn() or 0
    end
    entity.effectManager:addEffect(effect.applyEffect, nil, turnNumber)
    local effectName = i18n.t("log.effect." .. effect.applyEffect)
    if effectName:find("^%[%[missing") then effectName = effect.applyEffect end
    log_manager.add("trap", {
      messageKey = "log.trap.effect",
      params = { target = entityName, effect = effectName },
    })
  end

  log_manager.add("trap", {
    messageKey = "log.trap.trigger",
    params = { target = entityName },
  })

  if trap.oneShot then
    trap.triggered = true
    trap.state = "triggered"
  end
end

return M
