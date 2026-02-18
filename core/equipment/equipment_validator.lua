-- core/equipment/equipment_validator.lua - Validation equipement
local M = {}

local slots = require("core.equipment.equipment_slots")

function M.canEquipInSlot(item, slot, currentEquipment)
  if not item or not slot then return false, "invalid" end
  if not slots.isValidSlot(slot) then return false, "invalid_slot" end

  local allowedSlots = item.allowedSlots or (item.slot and { item.slot })
  if not allowedSlots then return false, "no_allowed_slots" end

  local slotAllowed = false
  for _, s in ipairs(allowedSlots) do
    if s == slot then slotAllowed = true break end
  end
  if not slotAllowed then return false, "slot_incompatible" end

  if slots.isRingSlot(slot) then
    if (item.slot or "") ~= "ring" then return false, "not_ring" end
  end

  if slot == "weapon_off" then
    local main = currentEquipment and currentEquipment.weapon_main
    if main and main.twoHanded then
      return false, "main_hand_two_handed"
    end
  end

  return true
end

function M.getRequiredUnequips(item, slot, currentEquipment)
  local result = {}
  if not item or not currentEquipment then return result end

  if slot == "weapon_main" and item.twoHanded then
    if currentEquipment.weapon_off then
      table.insert(result, "weapon_off")
    end
  end

  return result
end

return M
