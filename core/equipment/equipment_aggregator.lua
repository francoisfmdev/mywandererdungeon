-- core/equipment/equipment_aggregator.lua - Agregation des bonus
local M = {}

local function merge_table(target, source, mergeFn)
  if not source then return end
  for k, v in pairs(source) do
    if type(v) == "number" then
      target[k] = (target[k] or 0) + v
    end
  end
end

function M.computeBonuses(equipment)
  local result = {
    stats = {},
    resistances = {},
    elementalDamage = {},
    effects = {},
    ac = 0,
    attackBonus = 0,
    defenseBonus = 0,
    bonusMaxHp = 0,
    bonusMaxMp = 0,
  }

  if not equipment then return result end

  for slot, item in pairs(equipment) do
    if item and type(item) == "table" then
      local bonuses = item.bonuses or (item.base and item.base.bonuses) or item
      if bonuses.stats then merge_table(result.stats, bonuses.stats) end
      if bonuses.resistances then merge_table(result.resistances, bonuses.resistances) end
      if bonuses.elementalDamage then merge_table(result.elementalDamage, bonuses.elementalDamage) end
      if bonuses.effects then
        for _, e in ipairs(bonuses.effects) do table.insert(result.effects, e) end
      end
      if type(bonuses.ac) == "number" then result.ac = result.ac + bonuses.ac end
      if type(bonuses.attackBonus) == "number" then result.attackBonus = result.attackBonus + bonuses.attackBonus end
      if type(bonuses.defenseBonus) == "number" then result.defenseBonus = result.defenseBonus + bonuses.defenseBonus end
      if type(bonuses.bonusMaxHp) == "number" then result.bonusMaxHp = result.bonusMaxHp + bonuses.bonusMaxHp end
      if type(bonuses.bonusMaxMp) == "number" then result.bonusMaxMp = result.bonusMaxMp + bonuses.bonusMaxMp end
    end
  end

  return result
end

return M
