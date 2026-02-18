-- core/combat/entity_adapter.lua - Adapte Character -> entity combat
local M = {}

local EffectManager = require("core.effects.effect_manager")

function M.fromCharacter(character)
  if not character then return nil end
  local stats = {}
  local statNames = { "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma" }
  for _, n in ipairs(statNames) do
    stats[n] = character.getStat and character:getStat(n) or 1
  end
  local entity = {
    stats = stats,
    hp = character:getHP(),
    maxHp = character:getMaxHP(),
    mp = character:getMP(),
    maxMp = character:getMaxMP(),
    ac = 10,
    resistances = {},
    _character = character,
  }
  entity.effectManager = EffectManager.new(entity)
  if character.getEffectiveStat then
    entity.getEffectiveStat = function(_, n)
      local base = character:getEffectiveStat(n)
      local mods = entity.effectManager:getAggregatedModifiers()
      return (base or 0) + (mods.stats[n] or 0)
    end
  end
  if character.getEffectiveAC then
    entity.getEffectiveAC = function() return character:getEffectiveAC() end
  end
  if character.getArmorValue then
    entity.getArmorValue = function() return character:getArmorValue() end
  end
  if character.getEquipmentDefenseBonus then
    entity.getEquipmentDefenseBonus = function() return character:getEquipmentDefenseBonus() end
  end
  if character.getEquipmentAttackBonus then
    entity.getEquipmentAttackBonus = function() return character:getEquipmentAttackBonus() end
  end
  if character.getEffectiveResistances then
    entity.getEffectiveResistances = function()
      local base = character:getEffectiveResistances() or {}
      local mods = entity.effectManager:getAggregatedModifiers()
      local out = {}
      for k, v in pairs(base) do out[k] = (tonumber(v) or 0) end
      for k, v in pairs(mods.resistances or {}) do
        out[k] = (out[k] or 0) + (tonumber(v) or 0)
      end
      return out
    end
  end
  entity.hp = character:getHP()
  entity.maxHp = character:getMaxHP()
  return entity
end

function M.syncToCharacter(entity)
  if not entity or not entity._character then return end
  local c = entity._character
  if c.setHP then c:setHP(entity.hp) end
  if c.setMP then c:setMP(entity.mp) end
end

return M
