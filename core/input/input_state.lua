-- core/input/input_state.lua - Mode input (normal, menu, direction_target)
local M = {}

local _mode = "normal"
local _pendingAction = nil
local _pendingSpellId = nil
local _selectedDx, _selectedDy = 0, 0
local _observerGx, _observerGy = nil, nil

function M.getMode()
  return _mode or "normal"
end

local _useItemIndex = nil

function M.setMode(mode)
  _mode = mode or "normal"
  if mode ~= "direction_target" then
    _selectedDx, _selectedDy = 0, 0
    _pendingSpellId = nil
  end
  if mode ~= "observer" and mode ~= "use_item_target" then
    _observerGx, _observerGy = nil, nil
  end
  if mode ~= "use_item_target" then
    _useItemIndex = nil
  end
end

function M.getPendingAction()
  return _pendingAction
end

function M.setPendingAction(action)
  _pendingAction = action
end

function M.getPendingSpellId()
  return _pendingSpellId
end

function M.setPendingSpellId(spellId)
  _pendingSpellId = spellId
end

function M.clearPending()
  _pendingAction = nil
  _pendingSpellId = nil
  _selectedDx, _selectedDy = 0, 0
end

function M.setSelectedDirection(dx, dy)
  _selectedDx = dx or 0
  _selectedDy = dy or 0
end

function M.getSelectedDirection()
  return _selectedDx, _selectedDy
end

function M.isDirectionTarget()
  return _mode == "direction_target"
end

function M.isObserver()
  return _mode == "observer"
end

function M.isUseItemTarget()
  return _mode == "use_item_target"
end

function M.setUseItemIndex(index)
  _useItemIndex = index
end

function M.getUseItemIndex()
  return _useItemIndex
end

function M.setObserverCursor(gx, gy)
  _observerGx, _observerGy = gx, gy
end

function M.getObserverCursor()
  return _observerGx, _observerGy
end

function M.reset()
  _mode = "normal"
  _pendingAction = nil
  _pendingSpellId = nil
  _selectedDx, _selectedDy = 0, 0
  _observerGx, _observerGy = nil, nil
  _useItemIndex = nil
end

return M
