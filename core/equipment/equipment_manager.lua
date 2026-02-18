-- core/equipment/equipment_manager.lua - Gestion equipement
local M = {}

local slots = require("core.equipment.equipment_slots")
local validator = require("core.equipment.equipment_validator")
local aggregator = require("core.equipment.equipment_aggregator")

local function getItemData(item)
  if not item then return nil end
  return item.base or item
end

function M.new(owner)
  local self = {}
  self._owner = owner
  self._equipped = {}

  for _, slot in ipairs(slots.SLOTS) do
    self._equipped[slot] = nil
  end

  function self:equip(item, slot)
    if not item or not slot then return false, { code = "invalid_args" } end
    local itemData = getItemData(item)
    if not itemData then return false, { code = "invalid_item" } end

    local ok, err, extra = validator.canEquipInSlot(itemData, slot, self._equipped)
    if not ok then return false, { code = err or "unknown" } end

    local prevInSlot = self._equipped[slot]
    if prevInSlot and prevInSlot.cursed then
      return false, { code = "cursed_in_slot" }
    end

    local toUnequip = validator.getRequiredUnequips(itemData, slot, self._equipped)
    local freed = {}
    for _, s in ipairs(toUnequip) do
      local cur = self._equipped[s]
      if cur and cur.cursed then
        return false, { code = "cursed_in_slot" }
      end
      if cur then table.insert(freed, cur) end
      self._equipped[s] = nil
    end
    if prevInSlot then table.insert(freed, prevInSlot) end

    self._equipped[slot] = item
    return true, freed
  end

  function self:unequip(slot)
    if not slots.isValidSlot(slot) then return false, { code = "invalid_slot" } end
    local prev = self._equipped[slot]
    if prev and prev.cursed then
      return false, { code = "cursed" }
    end
    self._equipped[slot] = nil
    return true, prev
  end

  function self:getEquipped(slot)
    return self._equipped[slot]
  end

  function self:getAllEquipped()
    local result = {}
    for k, v in pairs(self._equipped) do
      if v then result[k] = v end
    end
    return result
  end

  function self:canEquip(item, slot)
    local itemData = getItemData(item)
    if not itemData then return false end
    local ok = validator.canEquipInSlot(itemData, slot, self._equipped)
    return ok
  end

  function self:getBonuses()
    return aggregator.computeBonuses(self._equipped)
  end

  function self:toSaveData()
    local data = {}
    for slot, item in pairs(self._equipped) do
      if item then
        data[slot] = self._itemToSaveData(item)
      end
    end
    return data
  end

  function self._itemToSaveData(item)
    if not item then return nil end
    local ItemInstance = require("core.equipment.item_instance")
    return ItemInstance.toSaveData(item)
  end

  function self:fromSaveData(data, itemFactory)
    if not data or type(data) ~= "table" then return end
    self._equipped = {}
    for _, s in ipairs(slots.SLOTS) do
      self._equipped[s] = nil
    end
    local factory = itemFactory
    if not factory then
      local ItemInstance = require("core.equipment.item_instance")
      factory = function(d) return ItemInstance.fromSaveData(d) end
    end
    for slot, itemData in pairs(data) do
      if slots.isValidSlot(slot) then
        local item = factory(itemData)
        if item then self._equipped[slot] = item end
      end
    end
  end

  return self
end

return M
