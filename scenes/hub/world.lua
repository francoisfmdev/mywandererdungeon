-- scenes/hub/world.lua - Carte monde, choix donjons (hub_screen FF style)
local M = {}
local hub_screen = require("core.hub_screen")

function M.new()
  return hub_screen.create("data/hub/world.lua")
end

return M
