-- scenes/hub/shop.lua
local M = {}
local hub_screen = require("core.hub_screen")
function M.new()
  return hub_screen.create("data/hub/shop.lua")
end
return M
