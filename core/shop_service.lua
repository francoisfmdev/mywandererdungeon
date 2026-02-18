-- core/shop_service.lua - Logique metier boutique (extensible)
local M = {}

function M.buy(item_id, quantity)
  return false
end

function M.sell(item_id, quantity)
  return false
end

function M.repair(item_id)
  return false
end

function M.handle(action)
  if action == "buy" then return M.buy(nil, 1) end
  if action == "sell" then return M.sell(nil, 1) end
  if action == "repair" then return M.repair(nil) end
  return false
end

return M
