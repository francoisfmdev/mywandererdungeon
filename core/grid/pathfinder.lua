-- core/grid/pathfinder.lua - A* 8 directions, coût 1 partout
local M = {}

local octo = require("core.grid.octo_dirs")

local function key(x, y)
  return ("%d,%d"):format(x, y)
end

local function heuristic(ax, ay, bx, by)
  local dx = math.abs(bx - ax)
  local dy = math.abs(by - ay)
  return math.max(dx, dy)
end

function M.find_path(map, fromX, fromY, toX, toY)
  if not map or not map.isWalkable or not map.inBounds then return nil end
  if not map:inBounds(fromX, fromY) or not map:inBounds(toX, toY) then return nil end
  if not map:isWalkable(toX, toY) then return nil end

  local open = {}
  local openSet = {}
  local gScore = {}
  local fScore = {}
  local cameFrom = {}

  local function push(node)
    local k = key(node.x, node.y)
    if openSet[k] then return end
    openSet[k] = true
    local f = (fScore[k] or 999999)
    table.insert(open, { x = node.x, y = node.y, f = f })
    table.sort(open, function(a, b) return a.f < b.f end)
  end

  local function pop()
    if #open == 0 then return nil end
    local n = table.remove(open, 1)
    openSet[key(n.x, n.y)] = nil
    return n
  end

  gScore[key(fromX, fromY)] = 0
  fScore[key(fromX, fromY)] = heuristic(fromX, fromY, toX, toY)
  push({ x = fromX, y = fromY, f = fScore[key(fromX, fromY)] })

  while #open > 0 do
    local current = pop()
    if not current then break end
    if current.x == toX and current.y == toY then
      local path = {}
      local c = { x = toX, y = toY }
      while c do
        table.insert(path, 1, { x = c.x, y = c.y })
        local k = key(c.x, c.y)
        c = cameFrom[k]
      end
      return path
    end

    local curKey = key(current.x, current.y)
    local curG = gScore[curKey] or 999999

    for _, d in octo.each_dir() do
      local nx = current.x + d.dx
      local ny = current.y + d.dy
      if map:inBounds(nx, ny) and map:isWalkable(nx, ny) then
        local cost = octo.get_cost(d)
        local tentG = curG + cost
        local nKey = key(nx, ny)
        if tentG < (gScore[nKey] or 999999) then
          cameFrom[nKey] = { x = current.x, y = current.y }
          gScore[nKey] = tentG
          fScore[nKey] = tentG + heuristic(nx, ny, toX, toY)
          push({ x = nx, y = ny, f = fScore[nKey] })
        end
      end
    end
  end

  return nil
end

return M
