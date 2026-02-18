-- scenes/hub/tavern.lua
local M = {}
local hub_screen = require("core.hub_screen")
function M.new()
  return hub_screen.create("data/hub/tavern.lua")
end
return M
