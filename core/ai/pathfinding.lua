-- core/ai/pathfinding.lua - 8 directions, premier pas vers cible
local M = {}

local pathfinder = require("core.grid.pathfinder")
local octo = require("core.grid.octo_dirs")

function M.find_path(map, fromX, fromY, toX, toY)
  return pathfinder.find_path(map, fromX, fromY, toX, toY)
end

--- Retourne dx, dy du premier pas vers (toX, toY), ou nil si aucun chemin.
--- isWalkable(x, y): optionnel, retourne true si la case est traversable (defaut: map:isWalkable)
function M.first_step_toward(map, fromX, fromY, toX, toY, isWalkable)
  isWalkable = isWalkable or function(x, y) return map:inBounds(x, y) and map:isWalkable(x, y) end
  local proxy = {
    inBounds = function(_, x, y) return map:inBounds(x, y) end,
    isWalkable = function(_, x, y) return isWalkable(x, y) end,
  }
  local path = pathfinder.find_path(proxy, fromX, fromY, toX, toY)
  if not path or #path < 2 then return nil, nil end
  local next_pos = path[2]
  return next_pos.x - fromX, next_pos.y - fromY
end

function M.each_dir()
  return octo.each_dir()
end

return M
