-- core/scene_manager.lua - Stack de scenes, push/pop/replace, cycle de vie
local M = {}

local log = require("core.log")
local _stack = {}
local _registry = {}
local _factory = nil

function M.set_factory(fn)
  _factory = fn
end

function M.register(id, factory_fn)
  _registry[id] = factory_fn
end

local function create_scene(id)
  if _registry[id] then
    return _registry[id]()
  end
  if _factory then
    return _factory(id)
  end
  log.error("scene_manager: unknown scene", id)
  return nil
end

function M.push(id)
  local scene = create_scene(id)
  if not scene then return false end
  local top = _stack[#_stack]
  if top and top.pause then top:pause() end
  table.insert(_stack, scene)
  if scene.enter then scene:enter() end
  return true
end

function M.pop()
  if #_stack == 0 then return false end
  local scene = table.remove(_stack)
  if scene.exit then scene:exit() end
  local top = _stack[#_stack]
  if top and top.resume then top:resume() end
  return true
end

function M.replace(id)
  local scene = create_scene(id)
  if not scene then return false end
  for i = #_stack, 1, -1 do
    local s = _stack[i]
    if s.exit then s:exit() end
    table.remove(_stack, i)
  end
  table.insert(_stack, scene)
  if scene.enter then scene:enter() end
  return true
end

function M.current()
  return _stack[#_stack]
end

function M.update(dt)
  local top = _stack[#_stack]
  if top and top.update then top:update(dt) end
end

function M.draw()
  for i = 1, #_stack do
    if _stack[i].draw then _stack[i]:draw() end
  end
end

return M
