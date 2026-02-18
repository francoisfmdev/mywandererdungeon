-- core/pending_dungeon_action.lua - Action differee (ex: use item depuis inventaire)
local M = {}

local _pending = nil

function M.set(action)
  _pending = action
end

function M.get()
  local p = _pending
  _pending = nil
  return p
end

function M.peek()
  return _pending
end

return M
