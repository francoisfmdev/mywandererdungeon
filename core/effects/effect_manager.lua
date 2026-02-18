-- core/effects/effect_manager.lua - Gestion des effets par entite
local M = {}

local registry = require("core.effects.effect_registry")
local damage_calculator = require("core.combat.damage_calculator")
local EffectInstance = require("core.effects.effect_instance")

local function apply_damage_effect(entity, damageSpec, damageType)
  if not entity then return end
  local amount
  if type(damageSpec) == "table" and (damageSpec.damageMin or damageSpec.damageMax) then
    amount = damage_calculator.rollMinMax(damageSpec.damageMin or 1, damageSpec.damageMax or 1)
  else
    return
  end
  if amount <= 0 then return end
  local resist = damage_calculator.applyResistance(amount, damageType, entity)
  local finalDamage = resist.damage or 0
  local healed = resist.healed or 0
  if healed > 0 and entity.hp then
    entity.hp = math.min((entity.hp or 0) + healed, entity.maxHp or 999)
    if entity._character and entity._character.setHP then
      entity._character:setHP(entity.hp)
    end
  end
  if finalDamage > 0 and entity.hp ~= nil then
    entity.hp = math.max(0, (entity.hp or 0) - finalDamage)
    if entity._character and entity._character.setHP then
      entity._character:setHP(entity.hp)
    end
    entity.shakeFrames = 12
  end
  return { damage = finalDamage, healed = healed }
end

local function run_hooks(instances, hookName, entity)
  local results = {}
  for _, inst in ipairs(instances) do
    local hook = inst.def and inst.def[hookName]
    if hook and type(hook) == "table" and (hook.damageMin or hook.damageMax) then
      local r = apply_damage_effect(entity, hook, hook.damageType or "physical")
      if r then table.insert(results, { effectId = inst.effectId, result = r }) end
    end
  end
  return results
end

local function aggregate_modifiers(instances)
  local agg = {
    stats = {},
    resistances = {},
    speed = 0,
  }
  for _, inst in ipairs(instances) do
    local mods = inst.def and inst.def.modifiers
    if mods then
      if mods.stats then
        for k, v in pairs(mods.stats) do
          agg.stats[k] = (agg.stats[k] or 0) + (tonumber(v) or 0)
        end
      end
      if mods.resistances then
        for k, v in pairs(mods.resistances) do
          agg.resistances[k] = (agg.resistances[k] or 0) + (tonumber(v) or 0)
        end
      end
      if type(mods.speed) == "number" then
        agg.speed = agg.speed + mods.speed
      end
    end
  end
  return agg
end

function M.new(entity)
  local self = {}
  self._entity = entity
  self._instances = {}

  function self:addEffect(effectId, sourceEntity, turnNumber)
    local def = registry.get(effectId)
    if not def then return false end

    local existing
    for i, inst in ipairs(self._instances) do
      if inst.effectId == effectId then
        existing = { idx = i, inst = inst }
        break
      end
    end

    if existing then
      if def.stacking == "ignore" then return false end
      if def.stacking == "refresh" then
        existing.inst.remaining = tonumber(def.duration) or 1
        existing.inst.sourceEntity = sourceEntity
        return true
      end
      if def.stacking == "stack" then
        local ni = EffectInstance.new(effectId, sourceEntity, turnNumber)
        if ni then table.insert(self._instances, ni) end
        return true
      end
    end

    local inst = EffectInstance.new(effectId, sourceEntity, turnNumber)
    if not inst then return false end
    table.insert(self._instances, inst)
    return true
  end

  function self:removeEffect(effectId)
    for i = #self._instances, 1, -1 do
      if self._instances[i].effectId == effectId then
        table.remove(self._instances, i)
      end
    end
  end

  function self:updateTurnStart(turnNumber)
    local hookResults = run_hooks(self._instances, "onTurnStart", self._entity)
    for _, inst in ipairs(self._instances) do
      inst.remaining = inst.remaining - 1
    end
    for i = #self._instances, 1, -1 do
      if self._instances[i].remaining <= 0 then
        table.remove(self._instances, i)
      end
    end
    return hookResults
  end

  function self:updateTurnEnd(turnNumber)
    return run_hooks(self._instances, "onTurnEnd", self._entity)
  end

  function self:decay(turnNumber)
    local toRemove = {}
    for i, inst in ipairs(self._instances) do
      inst.remaining = inst.remaining - 1
      if inst.remaining <= 0 then
        table.insert(toRemove, i)
      end
    end
    for i = #toRemove, 1, -1 do
      table.remove(self._instances, toRemove[i])
    end
  end

  function self:getAggregatedModifiers()
    return aggregate_modifiers(self._instances)
  end

  function self:getInstances()
    return self._instances
  end

  function self:hasEffect(effectId)
    for _, inst in ipairs(self._instances) do
      if inst.effectId == effectId then return true end
    end
    return false
  end

  function self:getBlockedActions()
    local blocked = { move = false, attack = false, cast = false, useItem = false }
    for _, inst in ipairs(self._instances) do
      local d = inst.def
      if d then
        if d.blockMove then blocked.move = true end
        if d.blockAttack then blocked.attack = true end
        if d.blockCast then blocked.cast = true end
        if d.blockUseItem then blocked.useItem = true end
      end
    end
    return blocked
  end

  function self:getMpCostMultiplier()
    local mult = 1
    for _, inst in ipairs(self._instances) do
      local m = inst.def and tonumber(inst.def.mpCostMultiplier)
      if m and m > 0 then mult = mult * m end
    end
    return mult
  end

  function self:getBlockRegen()
    for _, inst in ipairs(self._instances) do
      if inst.def and inst.def.blockRegen then return true end
    end
    return false
  end

  return self
end

return M
