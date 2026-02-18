-- scenes/hub/hub_main.lua
local M = {}
local hub_screen = require("core.hub_screen")
function M.new()
  return hub_screen.create("data/hub/hub_main.lua")
end
return M
