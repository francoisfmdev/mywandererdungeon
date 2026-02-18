-- core/effects/effect_instance.lua - Instance d'un effet applique a une entite
local M = {}

function M.new(effectId, sourceEntity, turnNumber)
  local registry = require("core.effects.effect_registry")
  local def = registry.get(effectId)
  if not def then return nil end

  local self = {}
  self.effectId = effectId
  self.sourceEntity = sourceEntity
  self.duration = tonumber(def.duration) or 1
  self.remaining = self.duration
  self.stacking = def.stacking or "refresh"
  self.type = def.type or "debuff"
  self.def = def
  self.appliedAtTurn = turnNumber or 0

  return self
end

return M
