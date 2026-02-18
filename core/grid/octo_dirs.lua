-- core/grid/octo_dirs.lua - 8 directions, coût 1 orthogonal et diagonal
local M = {}

M.DIRS = {
  { dx = 0,  dy = -1 }, -- N
  { dx = 1,  dy = -1 }, -- NE
  { dx = 1,  dy = 0  }, -- E
  { dx = 1,  dy = 1  }, -- SE
  { dx = 0,  dy = 1  }, -- S
  { dx = -1, dy = 1  }, -- SW
  { dx = -1, dy = 0  }, -- W
  { dx = -1, dy = -1 }, -- NW
}

function M.each_dir()
  return ipairs(M.DIRS)
end

function M.move(x, y, dir)
  if not dir or not dir.dx or not dir.dy then return x, y end
  return x + dir.dx, y + dir.dy
end

function M.get_cost(dir)
  return 1
end

return M
