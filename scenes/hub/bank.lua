-- scenes/hub/bank.lua
local M = {}
local hub_screen = require("core.hub_screen")
function M.new()
  return hub_screen.create("data/hub/bank.lua")
end
return M
