-- core/bank_service.lua - Logique metier banque
local M = {}
local player_data = require("core.player_data")

function M.deposit_gold(amount)
  if not amount or amount < 0 then return false end
  local g = player_data.get_gold()
  local actual = math.min(amount, g)
  if actual <= 0 then return false end
  player_data.set_gold(g - actual)
  player_data.set_bank_gold(player_data.get_bank_gold() + actual)
  return true
end

function M.withdraw_gold(amount)
  if not amount or amount < 0 then return false end
  local bg = player_data.get_bank_gold()
  local actual = math.min(amount, bg)
  if actual <= 0 then return false end
  player_data.set_bank_gold(bg - actual)
  player_data.set_gold(player_data.get_gold() + actual)
  return true
end

function M.deposit_item(index)
  local inv = player_data.get_inventory()
  local item = inv[index]
  if not item then return false end
  table.remove(inv, index)
  table.insert(player_data.get_bank_storage(), item)
  return true
end

function M.withdraw_item(index)
  local storage = player_data.get_bank_storage()
  local item = storage[index]
  if not item then return false end
  table.remove(storage, index)
  table.insert(player_data.get_inventory(), item)
  return true
end

function M.handle(action)
  if action == "deposit_gold" then
    return M.deposit_gold(100)
  elseif action == "withdraw_gold" then
    return M.withdraw_gold(100)
  elseif action == "deposit_items" then
    return true
  elseif action == "withdraw_items" then
    return true
  end
  return false
end

return M
