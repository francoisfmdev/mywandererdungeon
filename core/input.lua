-- core/input.lua - Abstraction input, mapping data-driven
local M = {}

local platform = require("platform.love")
local _bindings = {}
local _actions = {}
local _pressed_this_frame = {}

function M.load_bindings(bindings_path)
  local fs = require("core.fs")
  if not fs.exists(bindings_path) then return false end
  local ok, chunk = pcall(fs.read, bindings_path)
  if not ok or not chunk then return false end
  local fn, err = loadstring(chunk)
  if not fn then return false end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data and type(data) == "table" then
    _bindings = data
    M._build_action_map()
    return true
  end
  return false
end

function M.load_bindings_from_table(tbl)
  if tbl and type(tbl) == "table" then
    _bindings = tbl
    M._build_action_map()
    return true
  end
  return false
end

function M.get_bindings()
  return _bindings
end

function M.get_bindings_copy()
  local copy = {}
  for action, keys in pairs(_bindings) do
    copy[action] = {}
    for _, k in ipairs(keys) do copy[action][#copy[action] + 1] = k end
  end
  return copy
end

function M.set_binding(action, keys)
  if type(keys) == "table" then
    _bindings[action] = keys
    M._build_action_map()
    return true
  end
  return false
end

function M._build_action_map()
  _actions = {}
  for action, keys in pairs(_bindings) do
    if type(keys) == "table" then
      for _, k in ipairs(keys) do
        _actions[k] = _actions[k] or {}
        table.insert(_actions[k], action)
      end
    end
  end
end

function M.init()
  local config = require("core.config")
  local custom = config.get("bindings")
  if custom and type(custom) == "table" then
    M.load_bindings_from_table(custom)
  else
    M.load_bindings("data/input/bindings.lua")
  end
  platform.input_register(M._on_key, M._on_key_release)
end

function M._on_key(key)
  local acts = _actions[key]
  if acts then
    for _, a in ipairs(acts) do
      _pressed_this_frame[a] = true
    end
  end
end

function M._on_key_release(key) end

function M.is_pressed(action)
  return _pressed_this_frame[action] == true
end

function M.consume(action)
  if _pressed_this_frame[action] then
    _pressed_this_frame[action] = nil
    return true
  end
  return false
end

function M.end_frame()
  _pressed_this_frame = {}
end

function M.inject_wheel(dy)
  if dy > 0 then _pressed_this_frame["up"] = true
  elseif dy < 0 then _pressed_this_frame["down"] = true
  end
end

return M
