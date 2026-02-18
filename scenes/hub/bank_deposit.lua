local M = {}
local bank_items = require("scenes.hub.bank_items")
function M.new()
  return bank_items.new("deposit")
end
return M
