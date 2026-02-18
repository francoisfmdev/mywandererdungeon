-- core/equipment/equipment_slots.lua - Slots et regles
local M = {}

M.SLOTS = {
  "weapon_main",
  "weapon_off",
  "armor",
  "boots",
  "helmet",
  "cape",
  "ring_1",
  "ring_2",
  "necklace",
}

M.RING_SLOTS = { "ring_1", "ring_2" }

M.SHIELD_SLOT = "weapon_off"

function M.isValidSlot(slot)
  for _, s in ipairs(M.SLOTS) do
    if s == slot then return true end
  end
  return false
end

function M.isRingSlot(slot)
  return slot == "ring_1" or slot == "ring_2"
end

return M
